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

The order of terraform execution essentially does (in a VPC environment):

1) IAM permissions for lambda.
2) Creates SSH key via an exteral tf module, uploads to aws, will use key in lambda code (a directory with a `main.py` that exists here and will be zipped later) to ssh to it from lambda.
3) Create Instance to ssh to (with SSH key from step 2).
4) Use local-exec hooks on ssh creation to create zip files with the necessary data: ssh keys & ip address info.
4) Upload Lambda zip/archived code at the very end of the above process.

Then:

Execute a lambda function run - it should SSH in and show you it's disk usage.

# Lambda Package

The tl;dr lambda package that gets uploaded (ie, the `code` directory in this repo that gets zipped, minus the virtualenv dependencies).

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

