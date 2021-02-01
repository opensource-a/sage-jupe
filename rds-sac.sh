stackName=sage-jupe-101
permissionBoundary=arn:aws:iam::aws:policy/AdministratorAccess
notebookName=rdsconvertor.ipynb
rdsEndpoint=database-1-instance-1.cpuyvrxxbdak.us-east-1.rds.amazonaws.com
rdsUser=admin
rdsPassword=<password>
database=cities
query="select * from cities_data"

awsAccountId=$(aws sts get-caller-identity --query Account --output text)
s3InputBucket=$stackName-input-bucket-$awsAccountId
s3OutputBucket=$stackName-output-bucket-$awsAccountId

aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary
aws cloudformation wait stack-create-complete --stack-name $stackName

cd container
chmod +x build_and_push.sh
./build_and_push.sh notebook-runner-$stackName

cd ..

aws s3 cp $notebookName s3://$s3InputBucket/

aws s3 cp cities.csv s3://$s3InputBucket/

aws lambda invoke --function-name RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3InputBucket/$notebookName\", \"parameters\": {\"input_bucket\": \"$s3InputBucket\", \"output_bucket\": \"$s3OutputBucket\", \"rdsendpoint\": \"$rdsEndpoint\"}, \"user1\": \"$rdsUser\"}, \"password1\": \"$rdsPassword\"}, \"database1\": \"$database\"}, \"query\": \"$query\"}}" result.json

