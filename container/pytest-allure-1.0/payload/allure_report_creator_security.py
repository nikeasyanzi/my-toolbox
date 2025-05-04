#!/usr/bin/env python3
import argparse
import base64
import json
import os
import pickle
import pprint
from functools import partial

import requests
from requests import Response

# Set security_user & security_password according to Allure container configuration
security_user = "admin"
security_password = "OEinfra@allure"


ssl_verification = True


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """
    parser = argparse.ArgumentParser(
        description="""
        Submit test result to remote Allure server.
        """
    )

    # yapf: disable
    subparsers = parser.add_subparsers(help='sub-command help', dest='subcommand')
    parser_add = subparsers.add_parser('add', help='sub-command add')

    parser_add.add_argument('-i', '--id', required=True, action='store',
                            help='Project ID according to existent projects in your Allure container')
    parser_add.add_argument('-d', '--dir', required=True, action='store',
                            help='This directory is where you put the results locally, generally named as `allure-results`')
    parser_add.add_argument('-s', '--server', required=True, action='store',
                            help='The url where the Allure container is deployed. Ex:http://localhost:5050')
    parser_delete = subparsers.add_parser('delete', help='sub-command delete')
    parser_delete.add_argument('-i', '--id', required=True, action='store',
                               help='Project ID according to existent projects in your Allure container')
    parser_delete.add_argument('-s', '--server', required=True, action='store',
                               help='The url where the Allure container is deployed. Ex:http://localhost:5050')

    # yapf: enable
    args = parser.parse_args()
    return args


def log_response(response: Response):
    print("STATUS CODE:")
    print(response.status_code)
    if response.status_code != 200:
        pprint.pprint(response.text)
        return exit()
    # json_prettier_response_body = json.dumps(
    #    response.json(), indent=4, sort_keys=True
    # )
    # print("RESPONSE:")
    # print(json_prettier_response_body)
    print(response.json()["meta_data"]["message"])
    return response.json()


def get_authenticated_session(login_uri):
    print("------------------LOGIN-----------------")
    session = requests.Session()
    credentials_body = {
        "username": security_user,
        "password": security_password,
    }
    response = session.post(
        login_uri, json=credentials_body, verify=ssl_verification
    )
    log_response(response)
    session.headers["X-CSRF-TOKEN"] = session.cookies["csrf_access_token"]
    print("CSRF-ACCESS-TOKEN: " + session.cookies["csrf_access_token"])
    response = response.json()
    session.cookies["access_token_cookie"] = response["data"]["access_token"]
    session.cookies["refresh_token_cookie"] = response["data"]["refresh_token"]
    session.headers.update({"Content-Type": "application/json"})
    return session


def send_results_to_allure_server(
    session, project_id, send_results_uri, allure_results_directory
):
    def get_file_as_result(filename):
        file_path = allure_results_directory + "/" + filename

        if os.path.isfile(file_path):
            with open(file_path, "rb") as f:
                content = f.read()
                if content.strip():
                    b64_content = base64.b64encode(content)
                    result = {
                        "file_name": filename,
                        "content_base64": b64_content.decode("UTF-8"),
                    }
                    print(f"Successfully encoded result for {file_path}")
                    return result
                else:
                    print("Empty File skipped: " + file_path)
        else:
            print("Directory skipped: " + file_path)

    def gather_result_files(allure_results_directory):
        files = os.listdir(allure_results_directory)
        print("FILES:")
        results = [
            get_file_as_result(file)
            for file in files
            if get_file_as_result(file)
        ]
        return results

    print("------------------SEND-RESULTS------------------")
    request_body = {
        "results": gather_result_files(allure_results_directory),
    }
    uri_params = {
        "project_id": project_id,
        "force_project_creation": "true",
    }
    response = session.post(
        send_results_uri,
        params=uri_params,
        json=request_body,
        verify=ssl_verification,
    )
    log_response(response)


def get_all_projects(session, get_projects_uri):
    response = session.get(get_projects_uri, verify=ssl_verification)
    log_response(response)


def create_project(session, get_projects_uri, project_id):
    print("------------------CREATE-REPORT------------------")
    request_body = {
        "id": project_id,
    }
    response = session.post(
        get_projects_uri, json=request_body, verify=ssl_verification
    )
    log_response(response)


def search_project(session, search_projects_uri, project_id):
    print("------------------SEARCH-REPORT------------------")
    uri_params = {
        "id": project_id,
    }
    response = session.get(
        search_projects_uri, params=uri_params, verify=ssl_verification
    )
    log_response(response)


def generate_allure_report(session, project_id, generate_report_uri):
    """
    If you want to generate reports on demand use the endpoint `GET /generate-report` and disable the Automatic Execution >> `CHECK_RESULTS_EVERY_SECONDS: NONE`
    """
    print("------------------GENERATE-REPORT------------------")
    execution_name = "execution from my script"
    execution_from = "http://google.com"
    execution_type = "teamcity"

    uri_params = {
        "project_id": project_id,
        "execution_name": execution_name,
        "execution_from": execution_from,
        "execution_type": execution_type,
    }
    response = session.get(
        generate_report_uri, params=uri_params, verify=ssl_verification
    )
    result = log_response(response)
    print("ALLURE REPORT URL:")
    print(result["data"]["report_url"])


def delete_project(session, delete_projects_uri):
    print("------------------DELETE-REPORT------------------")
    response = session.delete(delete_projects_uri, verify=ssl_verification)
    log_response(response)


def logout_allure(session, logout_uri):
    print("------------------LOGOUT------------------")
    response = session.delete(logout_uri, verify=ssl_verification)
    log_response(response)


def add(args):
    allure_server = args.server
    project_id = args.id
    allure_results_directory = args.dir
    print("RESULTS DIRECTORY PATH: " + allure_results_directory)
    print("PROJECT ID: " + project_id)
    print("ALLURE SERVER: " + allure_server)
    # Connection configuration
    send_results_uri = f"{allure_server}/allure-docker-service/send-results"
    generate_report_uri = (
        f"{allure_server}/allure-docker-service/generate-report"
    )
    # get_projects_uri = f"{allure_server}/allure-docker-service/projects"
    # search_projects_uri = f"{allure_server}/allure-docker-service/projects/search"

    login_uri = f"{allure_server}/allure-docker-service/login"
    logout_uri = f"{allure_server}/allure-docker-service/logout"

    session = get_authenticated_session(login_uri)
    send_results_to_allure_server(
        session, project_id, send_results_uri, allure_results_directory
    )
    generate_allure_report(session, project_id, generate_report_uri)
    logout_allure(session, logout_uri)
    return


def delete(args):
    allure_server = args.server
    project_id = args.id
    # Connection configuration
    login_uri = f"{allure_server}/allure-docker-service/login"
    logout_uri = f"{allure_server}/allure-docker-service/logout"
    delete_projects_uri = (
        f"{allure_server}/allure-docker-service/projects/{project_id}"
    )

    session = get_authenticated_session(login_uri)
    delete_project(session, delete_projects_uri)
    logout_allure(session, logout_uri)
    return


def main():
    args = GetArgs()
    print(args)

    def switch(case):
        switcher = {
            "add": add,
            "delete": delete,
            # get() method of dictionary data type returns
            # value of passed argument if it is present
            # in dictionary otherwise second argument will
            # be assigned as default value of passed argument
        }
        return switcher[case]  # you can pass

    return switch(args.subcommand)(
        args
    )  # for Python 3 --> print(switchcase("a")(10))


if __name__ == "__main__":
    main()
