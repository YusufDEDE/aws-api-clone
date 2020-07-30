#!/bin/bash
APINAME=${1}
STAGENAME=${2}
LAMBDANAME=${3}
CLONEAPIID=${4}
USAGEPLANID=${5}
AWS_PROFILE=[PROFILENAME]
AWS_REGION=[AWSREGION]
AWS_ACCOUNT=[AWSACCOUNT]
METHOD=POST

echo "Closing API ${APINAME} from API ${CLONEAPIID}"
RESTAPIID=`aws apigateway create-rest-api --name "${APINAME}" --description "${APINAME}" --clone-from ${CLONEAPIID} --endpoint-configuration '{"types":["REGIONAL"]}' --profile ${AWS_PROFILE} | grep '"id"' | sed 's/,//g;s/ //g;s/"//g;' | awk -F: '{ print $2 }'`

echo RESTAPIID: ${RESTAPIID}

echo "Getting Resource"
RESOURCEID=`aws apigateway get-resources --rest-api-id ${RESTAPIID} --profile ${AWS_PROFILE} | grep '"id"' | sed 's/,//g;s/ //g;s/"//g;' | awk -F: '{ print $2 }'`

echo RESOURCEID: ${RESOURCEID}

echo "Setting Lambda ${LAMBDANAME}"
LAMBDA_URL="arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT}:function:${LAMBDANAME}/invocations"
aws apigateway put-integration --rest-api-id ${RESTAPIID} --resource-id ${RESOURCEID} --http-method ${METHOD} --type AWS --integration-http-method ${METHOD} --uri "${LAMBDA_URL}" --profile ${AWS_PROFILE} | grep uri

SID=`uuidgen`

echo "Creating Initial Deployment for ${APINAME} API and Stage ${STAGENAME}"
DEPLOYMENTID=`aws apigateway create-deployment --rest-api-id ${RESTAPIID} --stage-name '' --profile ${AWS_PROFILE} | grep '"id"' | sed 's/,//g;s/ //g;s/"//g;' | awk -F: '{ print $2 }'`

echo "Adding Stage in Usageplan"
aws apigateway update-usage-plan --usage-plan-id ${USAGEPLANID} --patch-operations op="add",path="/apiStages",value="${RESTAPIID}:${STAGENAME}" --profile ${AWS_PROFILE} | grep name
sleep 10

echo "Redeploying Stage"
aws apigateway create-deployment --rest-api-id ${RESTAPIID} --stage-name ${STAGENAME} --description ${STAGENAME} --profile ${AWS_PROFILE} | grep description
sleep 5
echo "REST API Endpoints configured and deployed successfully.."