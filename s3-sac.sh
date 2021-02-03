stackName=sage-jupe-101
permissionBoundary=arn:aws:iam::aws:policy/AdministratorAccess
notebookName=convertor.ipynb

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

aws lambda invoke --function-name $stackName-RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3InputBucket/$notebookName\", \"parameters\": {\"input_bucket\": \"$s3InputBucket\", \"output_bucket\": \"$s3OutputBucket\"}}" result.json

