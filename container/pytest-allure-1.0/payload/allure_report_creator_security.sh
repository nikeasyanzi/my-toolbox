#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT
#set -x
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# This directory is where you have all your results locally, generally named as `allure-results`
ALLURE_RESULTS_DIRECTORY=""
# This url is where the Allure container is deployed. We are using localhost as example
ALLURE_SERVER=''

# Project ID according to existent projects in your Allure container - Check endpoint for project creation >> `[POST]/projects`
PROJECT_ID=""
#PROJECT_ID='my-project-id'
# Set SECURITY_USER & SECURITY_PASS according to Allure container configuration
SECURITY_USER='admin'
SECURITY_PASS='OEinfra@allure'

access_token_cookie=""
csrf_access_token=""
refresh_token_cookie=""
csrf_refresh_token=""
login_allure(){
    echo "------------------LOGIN-----------------"
    #curl -X POST "$ALLURE_SERVER/allure-docker-service/send-results?project_id=$PROJECT_ID" -H 'Content-Type: multipart/form-data' $FILES -ik

    RESPONSE=$(curl --cookie cookiesFile "$ALLURE_SERVER/allure-docker-service/login" -X POST \
        -H 'Content-Type: application/json' \
        -d "{
            "\""username"\"": "\""$SECURITY_USER"\"",
            "\""password"\"": "\""$SECURITY_PASS"\""
        }" -ik)
        
    RESULT=$(echo $RESPONSE) 
    [[ $? -ne 0 ]] && echo "Fail to login, please check the server url and login credential is correct!" && exit
    echo $(echo $RESULT | rev | cut -d: -f 1 | rev | cut -d} -f 1 )    
    echo
    echo "------------------EXTRACTING-CSRF-ACCESS-TOKEN------------------"
    access_token_cookie=$(echo $RESULT | grep -E "access_token_cookie=.*;" | cut -d\= -f 2 | cut -d\; -f 1)
    csrf_access_token=$(echo $RESULT | grep -E "csrf_access_token=.*;" | cut -d\= -f 4 | cut -d\; -f 1)
    refresh_token_cookie=$(echo $RESULT | grep -E "refresh_token_cookie=.*;" | cut -d\= -f 6 | cut -d\; -f 1)
    csrf_refresh_token=$(echo $RESULT | grep -E "csrf_refresh_token=.*;" | cut -d\= -f 8 | cut -d\; -f 1)

    #cat cookiesFile
    echo access_token_cookie:$access_token_cookie 
    echo csrf_access_token:$csrf_access_token 
    echo refresh_token_cookie:$refresh_token_cookie 
    echo csrf_refresh_token:$csrf_refresh_token
    echo
}
check_project_exist(){
    echo "------------------CHECK IF REPORT EXIST------------------"
    RESPONSE=$(curl -X GET "$ALLURE_SERVER/allure-docker-service/projects/$PROJECT_ID" -H  "accept: */*"  --cookie "access_token_cookie=$access_token_cookie")
    ALLURE_REPORT=$(echo $RESPONSE | jq ".meta_data.message" )
    #echo $RESPONSE
    [[ $ALLURE_REPORT = *"Project successfully obtained"* ]] && echo "Project $PROJECT_ID exists" || echo "Project $PROJECT_ID does not exist"
}
send_result(){
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    FILES_TO_SEND=$(ls -dp $DIR/$ALLURE_RESULTS_DIRECTORY/* | grep -v /$)
    if [ -z "$FILES_TO_SEND" ]; then
        exit 1
    fi

    FILES=''
    for FILE in $FILES_TO_SEND; do
        FILES+="-F files[]=@$FILE "
    done

    #Upload the result and create the project by setting force_project_creation to true
    echo "------------------SEND-RESULTS------------------"
    RESPONSE=$(curl -X POST "$ALLURE_SERVER/allure-docker-service/send-results?project_id=$PROJECT_ID&force_project_creation=true" -H  "accept: */*" \
    -H  "X-CSRF-TOKEN: $csrf_access_token" \
    -H  "Content-Type: multipart/form-data" \
    --cookie "access_token_cookie=$access_token_cookie" \
    $FILES)
    echo $RESPONSE | jq ".meta_data.message"
}

generate_report(){
    #If you want to generate reports on demand use the endpoint `GET /generate-report` and disable the Automatic Execution >> `CHECK_RESULTS_EVERY_SECONDS: NONE`
    echo "------------------GENERATE-REPORT------------------"
    EXECUTION_NAME='execution_from_my_bash_script'
    EXECUTION_FROM='http://google.com'
    EXECUTION_TYPE='bamboo'

    #You can try with a simple curl
    RESPONSE=$(curl -X GET "$ALLURE_SERVER/allure-docker-service/generate-report?project_id=$PROJECT_ID&execution_name=$EXECUTION_NAME&execution_from=$EXECUTION_FROM&execution_type=$EXECUTION_TYPE" -H "X-CSRF-TOKEN: $csrf_access_token" -H  "accept: */*" --cookie "access_token_cookie=$access_token_cookie" )
    #echo $RESPONSE
    #ALLURE_REPORT=$(grep -o '"report_url":"[^"]*' <<< "$RESPONSE" | grep -o '[^"]*$')
    #OR You can use JQ to extract json values -> https://stedolan.github.io/jq/download/
    echo $RESPONSE | jq '.data.report_url'
}

arg_parse(){
    while true; do
        #[[ "$#" == 0 ]] && break
        [[ -z "$@" ]] && break
        case $1 in
            -v | --verbose) set -x ;;
            --no-color) NO_COLOR=1 ;;
            -h | --help)
                usage
                ;;
            -i | --id)
		        PROJECT_ID="$2"
                ;;
            -d | --dir)
		        ALLURE_RESULTS_DIRECTORY="$2"
                ;;
            -s | --server)
		        ALLURE_SERVER="$2"
                ;;
            *)
                echo "Invalid command, please follow instructions"
                usage
                exit
                ;;
        esac
        shift 2
    done
    echo "ProjectID: $PROJECT_ID"
    echo "ALLURE_RESULTS_DIRECTORY: $ALLURE_RESULTS_DIRECTORY"
    echo "Server: $ALLURE_SERVER"
}

delete_report(){
    echo "------------------DELETE REPORT------------------"
    RESPONSE=$(curl -X DELETE "$ALLURE_SERVER/allure-docker-service/projects/$PROJECT_ID" -H "X-CSRF-TOKEN: $csrf_access_token" -H  "accept: */*" --cookie "access_token_cookie=$access_token_cookie" )
    echo $RESPONSE | jq ".meta_data.message"
}

logout_allure(){
    echo "------------------LOGOUT------------------"
    RESPONSE=$(curl -X DELETE "$ALLURE_SERVER/allure-docker-service/logout" -H "X-CSRF-TOKEN: $csrf_access_token" --cookie "access_token_cookie=$access_token_cookie" )
    echo $RESPONSE | jq ".meta_data.message"
}

usage() {
    cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [subcommand] [options]

Available subcommand:
    add         submit a test result to a allure server.

    delete      delete a test project from a allure server.

Available options:
-h, --help      Print this help and exit
-s, --server    Allure server URL, default: http://localhost:5050"
-i, --id        Allure project ID, defualt ID: default
-v, --verbose)  set -x 
--no-color,     NO_COLOR=1
-d, --dir       Allure report directory name, default: test_report

Example:
Upload a report:
    ./allure_report_creator_security.py.sh add -i <Project ID> -d <Report dir> -s <Server url>

Delete a project:
    ./allure_report_creator_security.py.sh delete -i <Project ID> -s <Server url>
EOF
exit
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # script cleanup here
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

setup_colors
subcommand=$1
shift 1
case $subcommand in
    add)
        now=$(date +"%T")
        echo "Current time : $now"
        arg_parse "$@"
        ( [[ -z "$PROJECT_ID" ]] || [[ -z "$ALLURE_RESULTS_DIRECTORY" ]] || [[ -z "$ALLURE_SERVER" ]] ) && die "Unknown options for add" 
        login_allure
        send_result
        generate_report
        logout_allure
        ;;
    delete)
        arg_parse "$@"
        ( [[ -z "$PROJECT_ID" ]] || [[ -z "$ALLURE_SERVER" ]] ) && die "Unknown options for delete"
        login_allure 
        delete_report
        logout_allure
        ;;
    help| -h)
        usage
        ;;
    *)
        die "Unknown subcommand: $subcommand" 
        ;;
esac

exit 0
