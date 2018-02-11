# How was this built?

The gist of this module is:

```
shai@adsk-lappy ~/tmp/foo   % tree
.
├── __init__.py
├── main.py
└── secrets
    ├── an_ssh_access_lambda-env-an_ssh_access_lambda.pem
    ├── an_ssh_access_lambda-env-an_ssh_access_lambda.pub
    └── ip_address.txt
```

On top of that, paramiko is necessary for SSH. virtual env python 3.6 on top of that was built via https://github.com/lambci/docker-lambda ie

```
# build
docker run -v $PWD/code:/var/task -it lambci/lambda:build-python3.6 bash

# test
docker run --rm -v $PWD:/var/task lambci/lambda:python3.6 main.lambda_handler
```
