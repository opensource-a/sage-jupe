#!/bin/bash

while read assign; do
 export "$assign";
done < <(sed -nE 's/([a-z_0-9]+): (.*)/\1=\2/ p' parameters.yml)


awsAccountId=$(aws sts get-caller-identity --query Account --output text)
timestamp=$(date "+%Y%m%d-%H%M%S")
stackName=runnotebook-$notebookName-$timestamp

echo $stackName



#aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary ParameterKey=S3BucketName,ParameterValue=$s3bucket
aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary ParameterKey=S3InputBucketName,ParameterValue=$inputs3bucket ParameterKey=S3InputPrefix1,ParameterValue=$input_prefix1 ParameterKey=S3InputPrefix2,ParameterValue=$input_prefix2 ParameterKey=S3TempBucketName,ParameterValue=$temp_bucket ParameterKey=S3NotebookPrefix,ParameterValue=$stackName/notebooks ParameterKey=S3NotebookKey,ParameterValue=$notebookName.ipynb ParameterKey=ProcessingInstanceType,ParameterValue=$processingInstanceType ParameterKey=ProcessingJobSecurityGroup,ParameterValue=$securityGroup ParameterKey=ProcessingJobSubnetId,ParameterValue=$subnetId ParameterKey=Timestamp,ParameterValue=$timestamp  
aws cloudformation wait stack-create-complete --stack-name $stackName

lambdaarn=arn:aws:lambda:us-east-1:$awsAccountId:function:$stackName-invoke
cp s3triggerlambdaconfigtemplate.json s3triggerlambdaconfig.json
sed -i  "s/#lambdaarn/$lambdaarn/g" s3triggerlambdaconfig.json
sed -i  "s/#prefix1/$input_prefix1/g" s3triggerlambdaconfig.json
sed -i  "s/#prefix2/$input_prefix2/g" s3triggerlambdaconfig.json

aws s3api put-bucket-notification-configuration --bucket $inputs3bucket --notification-configuration file://s3triggerlambdaconfig.json

cp $notebookPath/${notebookName}_parameters.yml container/parameters.yml
cd container
chmod +x build_and_push.sh
./build_and_push.sh $stackName

cd ..

aws s3 cp $notebookPath/$notebookName.ipynb s3://$temp_bucket/$stackName/notebooks/$notebookName.ipynb

#aws s3 cp cities.csv s3://$inputs3bucket/$input_prefix1/

#aws lambda invoke --function-name $stackName-RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3bucket/notebooks/$notebookName\", \"extra_args\": {\"NetworkConfig\": {\"VpcConfig\": {\"SecurityGroupIds\": [\"$securityGroup\"], \"Subnets\": [\"$subnetId\"]}}}}" result.json

