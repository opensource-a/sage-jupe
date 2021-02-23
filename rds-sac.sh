#!/bin/bash

while read assign; do
 export "$assign";
done < <(sed -nE 's/([a-z_]+): (.*)/\1=\2/ p' parameters.yml)


awsAccountId=$(aws sts get-caller-identity --query Account --output text)



aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary ParameterKey=S3BucketName,ParameterValue=$s3bucket
aws cloudformation wait stack-create-complete --stack-name $stackName

cp parameters.yml container/parameters.yml
cd container
chmod +x build_and_push.sh
./build_and_push.sh notebook-runner-$stackName

cd ..

aws s3 cp $notebookName s3://$s3bucket/notebooks/

aws s3 cp cities.csv s3://$s3bucket/input/

aws lambda invoke --function-name $stackName-RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3bucket/notebooks/$notebookName\", \"extra_args\": {\"NetworkConfig\": {\"VpcConfig\": {\"SecurityGroupIds\": [\"$securityGroup\"], \"Subnets\": [\"$subnetId\"]}}}}" result.json

