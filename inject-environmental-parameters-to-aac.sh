#!/bin/bash

while read assign; do
 export "$assign";
done < <(sed -nE 's/([a-z_0-9]+): (.*)/\1=\2/ p' parameters.yml)

awsAccountId=$(aws sts get-caller-identity --query Account --output text)
stackName=$1

arr_input_prefix1=(${input_prefix1//// })
table1=${arr_input_prefix1[-1]}
arr_input_prefix2=(${input_prefix2//// })
table2=${arr_input_prefix2[-1]}

gluedatabase=$stackName-glue-db-$awsAccountId
athenaworkgroup=$stackName-athena-workgroup-$awsAccountId

cp $notebookPath/${originalnotebookName}_parameters_template.yaml $notebookPath/${originalnotebookName}_parameters.yaml
sed -i  "s/#gluedatabase/$gluedatabase/g" $notebookPath/${originalnotebookName}_parameters.yaml
sed -i  "s/#gluetable1/$table1/g" $notebookPath/${originalnotebookName}_parameters.yaml
sed -i  "s/#gluetable2/$table2/g" $notebookPath/${originalnotebookName}_parameters.yaml
sed -i  "s/#athenaworkgroup/$athenaworkgroup/g" $notebookPath/${originalnotebookName}_parameters.yaml

echo "Notebook files injected with parameters correctly"
