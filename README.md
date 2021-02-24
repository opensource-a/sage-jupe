# sage-jupe
To execute, clone or copy this repo into a linux server that has docker and awscli 



To run the rds to s3 data to json convertor 
1. ```sudo aws configure``` and edit only the region to us-east-1
2. Edit rds-sac.sh (first few lines) with the correct parameter values
3. ```chmod +x rds-sac.sh```
4. ```sudo ./rds-sac.sh```
