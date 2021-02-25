#!/bin/bash

while read assign; do
 export "$assign";
done < <(sed -nE 's/([a-z_0-9]+): (.*)/\1=\2/ p' parameters.yml)


awsAccountId=$(aws sts get-caller-identity --query Account --output text)
timestamp=$(date "+%Y%m%d-%H%M%S")
stackName=runnotebook-$notebookName-$timestamp

echo $stackName

schemadefinition1=$(cat schemadefinition1.json | tr -d '\n')
schemadefinition2=$(cat schemadefinition2.json | tr -d '\n')

cp cloudformation.yml injected-cloudformation.yml
sed -i  "s/#schemadefinition1/$schemadefinition1/g" injected-cloudformation.yml
sed -i  "s/#schemadefinition2/$schemadefinition2/g" injected-cloudformation.yml

aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/injected-cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary ParameterKey=S3InputBucketName,ParameterValue=$inputs3bucket ParameterKey=S3InputPrefix1,ParameterValue=$input_prefix1 ParameterKey=S3InputPrefix2,ParameterValue=$input_prefix2 ParameterKey=S3TempBucketName,ParameterValue=$temp_bucket ParameterKey=S3NotebookPrefix,ParameterValue=$stackName/notebooks ParameterKey=S3NotebookKey,ParameterValue=$notebookName.ipynb ParameterKey=ProcessingInstanceType,ParameterValue=$processingInstanceType ParameterKey=ProcessingJobSecurityGroup,ParameterValue=$securityGroup ParameterKey=ProcessingJobSubnetId,ParameterValue=$subnetId ParameterKey=Timestamp,ParameterValue=$timestamp  
aws cloudformation wait stack-create-complete --stack-name $stackName

lambdaarn=arn:aws:lambda:us-east-1:$awsAccountId:function:$stackName-invoke
cp s3triggerlambdaconfigtemplate.json s3triggerlambdaconfig.json
sed -i  "s/#lambdaarn/$lambdaarn/g" s3triggerlambdaconfig.json
sed -i  "s/#prefix1/$input_prefix1/g" s3triggerlambdaconfig.json
sed -i  "s/#prefix2/$input_prefix2/g" s3triggerlambdaconfig.json

aws s3api put-bucket-notification-configuration --bucket $inputs3bucket --notification-configuration file://s3triggerlambdaconfig.json

#cp $notebookPath/${notebookName}_parameters.yaml container/parameters.yml
cd container
#gluedatabase=$stackName-glue-db-$awsAccountId
#athenaworkgroup=$stackName-athena-workgroup-$awsAccountId
#sed -i  "s/#gluedatabase/$gluedatabase/g" parameters.yml
#sed -i  "s/#gluetable1/$input_prefix1/g" parameters.yml
#sed -i  "s/#gluetable2/$input_prefix2/g" parameters.yml
#sed -i  "s/#athenaworkgroup/$athenaworkgroup/g" parameters.yml
chmod +x build_and_push.sh
./build_and_push.sh $stackName

cd ..

aws s3 cp $notebookPath/ s3://$temp_bucket/$stackName/notebooks/ --recursive

#aws s3 cp cities.csv s3://$inputs3bucket/$input_prefix1/

#aws lambda invoke --function-name $stackName-RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3bucket/notebooks/$notebookName\", \"extra_args\": {\"NetworkConfig\": {\"VpcConfig\": {\"SecurityGroupIds\": [\"$securityGroup\"], \"Subnets\": [\"$subnetId\"]}}}}" result.json

