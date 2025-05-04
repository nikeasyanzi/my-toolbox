#!/bin/bash

# This directory is where you have all your results locally, generally named as `allure-results`
ALLURE_RESULTS_DIRECTORY=$1
# This url is where the Allure container is deployed. We are using localhost as example
[[ -n "$3" ]] && ALLURE_SERVER="$3" || ALLURE_SERVER='http://os1-ci-server.asiapacific.hpqcorp.net:5050'
# Project ID according to existent projects in your Allure container - Check endpoint for project creation >> `[POST]/projects`
PROJECT_ID=$2
#PROJECT_ID='my-project-id'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILES_TO_SEND=$(ls -dp $DIR/$ALLURE_RESULTS_DIRECTORY/* | grep -v /$)
if [ -z "$FILES_TO_SEND" ]; then
  exit 1
fi

FILES=''
for FILE in $FILES_TO_SEND; do
  FILES+="-F files[]=@$FILE "
done

#set -o xtrace
main (){
echo "------------------Check if project exists------------------"
RESPONSE=$(curl -X GET "$ALLURE_SERVER/allure-docker-service/projects")
ALLURE_REPORT=$(echo $RESPONSE | jq ".data.projects | has(\"$PROJECT_ID\")" )
#echo $ALLURE_REPORT
if [[ $ALLURE_REPORT == "false" ]]; then
    echo "------------------Create project------------------"
    response=$(curl -X POST "$ALLURE_SERVER/allure-docker-service/projects" -H  "accept: */*" -H  "Content-Type: application/json" -d "{\"id\":\"$PROJECT_ID\"}")
    response=$(echo $response | jq ".meta_data.message")
    echo $response
else
    echo Project $PROJECT_ID exists
fi

echo "------------------SEND-RESULTS------------------"
curl -X POST "$ALLURE_SERVER/allure-docker-service/send-results?project_id=$PROJECT_ID" -H 'Content-Type: multipart/form-data' $FILES -ik

#If you want to generate reports on demand use the endpoint `GET /generate-report` and disable the Automatic Execution >> `CHECK_RESULTS_EVERY_SECONDS: NONE`
#echo "------------------GENERATE-REPORT------------------"
EXECUTION_NAME='execution_from_my_bash_script'
EXECUTION_FROM='http://google.com'
EXECUTION_TYPE='bamboo'

#You can try with a simple curl
RESPONSE=$(curl -X GET "$ALLURE_SERVER/allure-docker-service/generate-report?project_id=$PROJECT_ID&execution_name=$EXECUTION_NAME&execution_from=$EXECUTION_FROM&execution_type=$EXECUTION_TYPE" $FILES)
ALLURE_REPORT=$(grep -o '"report_url":"[^"]*' <<< "$RESPONSE" | grep -o '[^"]*$')

#OR You can use JQ to extract json values -> https://stedolan.github.io/jq/download/
ALLURE_REPORT=$(echo $RESPONSE | jq '.data.report_url')
echo $ALLURE_REPORT
}

main "$@"
