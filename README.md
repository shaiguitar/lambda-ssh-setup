# SSH & Lambda Example

First off, consider using Amazon SSM.

# Usage

An working example/proof of concept of using lambda to ssh into an instance in a VPC.

```
# set terraform version, https://github.com/Yleisradio/homebrew-terraforms
chtf 0.11.3

terraform init
terraform get

# set aws env vars
awsswitch $YOUR_ACCOUNT

# if you'd like verbose/debug:
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/$YOUR_ACCOUNT-tf.log

# create the lambda zip initially before terraforming
# it will be modified again during apply.
bash zip_lambda_code.sh

# if you're into planning before applying battles:
terraform plan

# apply the lambda
terraform apply
```

# Synopsis

The order of terraform execution in a VPC environment is essentially:

- IAM permissions for lambda.
- Creates SSH key via an exteral tf module, uploads to aws, will use key in lambda code (`main.py` that exists here and will be zipped later) to ssh to it from lambda.
- Create Instance to ssh to (with SSH key from step 2).
- local-exec hooks on ssh creation to create zip files with the necessary data: ssh keys & ip address info.
- Lambda zip/archived code at the very end of the above process.

Then:

Execute a lambda function run - it should SSH in and show you it's disk usage.

# Lambda Package

The entry point of the python lambda code is `main.py`. Please refer to that file to see the lambda execution. The lesser involved tl;dr lambda package that gets uploaded below. (ie, the `code` directory in this repo that gets zipped, minus the virtualenv dependencies).

```
# note, the secrets get created on terraform apply.

├── __init__.py
├── main.py
└── secrets
    ├── an_ssh_access_lambda-env-an_ssh_access_lambda.pem
    ├── an_ssh_access_lambda-env-an_ssh_access_lambda.pub
    └── ip_address.txt

```

# Result

![df-output](images/works.png?raw=true "df-output")

# Other info

https://aws.amazon.com/blogs/compute/scheduling-ssh-jobs-using-aws-lambda/
