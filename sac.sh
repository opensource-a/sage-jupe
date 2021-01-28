s3BucketName=sage-jupe-test-101
stackName=sage-jupe-101
permissionBoundary=arn:aws:iam::aws:policy/AdministratorAccess
notebookName=convertor.ipynb

aws cloudformation create-stack --stack-name $stackName --template-body file://$(pwd)/cloudformation.yml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=PermissionsBoundary,ParameterValue=$permissionBoundary
aws cloudformation wait stack-create-complete --stack-name $stackName


cd container
chmod +x build_and_push.sh
./build_and_push.sh notebook-runner-$stackName

cd ..

aws s3 mb s3://$s3BucketName
aws s3 cp $notebookName s3://$s3BucketName/

aws s3 cp cities.csv s3://$s3BucketName/

aws lambda invoke --function-name RunNotebook --payload "{\"image\": \"notebook-runner-$stackName\", \"input_path\": \"s3://$s3BucketName/$notebookName\", \"parameters\": {\"input_bucket\": \"$s3BucketName\"}}" result.json

