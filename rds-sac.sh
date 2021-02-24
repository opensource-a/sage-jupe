#!/bin/bash

while read assign; do
 export "$assign";
done < <(sed -nE 's/([a-z_]+): (.*)/\1=\2/ p' parameters.yml)


awsAccountId=$(aws sts get-caller-identity --query Account --output text)
stackName=runnotebook-$notebookName-$(date "+%Y%m%d-%H%M%S")

echo $stackName



#aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary ParameterKey=S3BucketName,ParameterValue=$s3bucket
aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary ParameterKey=S3InputBucketName,ParameterValue=$inputs3bucket ParameterKey=S3InputPrefix1,ParameterValue=$input_prefix1 ParameterKey=S3InputPrefix2,ParameterValue=$input_prefix2 ParameterKey=S3TempBucketName,ParameterValue=$temp_bucket ParameterKey=S3NotebookPrefix,ParameterValue=$stackName/notebooks ParameterKey=S3NotebookKey,ParameterValue=$notebookName.ipynb ParameterKey=ProcessingInstanceType,ParameterValue=$processingInstanceType ParameterKey=ProcessingJobSecurityGroup,ParameterValue=$securityGroup ParameterKey=ProcessingJobSubnetId,ParameterValue=$subnetId ParameterKey=Timestamp,ParameterValue=$(date "+%Y%m%d-%H%M%S")  
aws cloudformation wait stack-create-complete --stack-name $stackName

cp $notebookPath/$notebookName_parameters.yml container/parameters.yml
cd container
chmod +x build_and_push.sh
./build_and_push.sh $stackName

cd ..

aws s3 cp $notebookPath/$notebookName.ipynb s3://$temp_bucket/$stackName/notebooks/$notebookName.ipynb

#aws s3 cp cities.csv s3://$inputs3bucket/$input_prefix1/

#aws lambda invoke --function-name $stackName-RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3bucket/notebooks/$notebookName\", \"extra_args\": {\"NetworkConfig\": {\"VpcConfig\": {\"SecurityGroupIds\": [\"$securityGroup\"], \"Subnets\": [\"$subnetId\"]}}}}" result.json

