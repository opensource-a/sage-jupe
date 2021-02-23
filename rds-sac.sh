stackName=sage-jupe-101
permissionBoundary=arn:aws:iam::aws:policy/AdministratorAccess
notebookName=rdsconvertor.ipynb
securityGroup=<sg-id>
subnetId=<subnet-id>
rdsEndpoint=<rds-host-endpoint>
rdsUser=admin
rdsPassword=<password>
database=cities
query="select * from cities_data"
output_prefix=output

awsAccountId=$(aws sts get-caller-identity --query Account --output text)
s3Bucket=$stackName-bucket-$awsAccountId


aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary
aws cloudformation wait stack-create-complete --stack-name $stackName

cd container
chmod +x build_and_push.sh
./build_and_push.sh notebook-runner-$stackName

cd ..

cp $notebookName injected-$notebookName

sed -i  "s/#input_bucket/$s3Bucket/g" injected-$notebookName
sed -i  "s/#output_bucket/$s3Bucket/g" injected-$notebookName
sed -i  "s/#rdsendpoint/$rdsEndpoint/g" injected-$notebookName
sed -i  "s/#user/$rdsUser/g" injected-$notebookName
sed -i  "s/#password/$rdsPassword/g" injected-$notebookName
sed -i  "s/#querydatabase/$database/g" injected-$notebookName
sed -i  "s/#querystring/$query/g" injected-$notebookName

aws s3 cp injected-$notebookName s3://$s3Bucket/notebooks/

aws s3 cp cities.csv s3://$s3Bucket/input/

aws lambda invoke --function-name $stackName-RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3Bucket/notebooks/injected-$notebookName\", \"extra_args\": {\"NetworkConfig\": {\"VpcConfig\": {\"SecurityGroupIds\": [\"$securityGroup\"], \"Subnets\": [\"$subnetId\"]}}}}" result.json

