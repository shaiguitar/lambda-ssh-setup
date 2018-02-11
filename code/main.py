import os
import base64
import io
import paramiko

def get_ssh_key():
    keypath = 'secrets/an_ssh_access_lambda-env-an_ssh_access_lambda.pem'
    data = open(keypath).read()
    return data

def get_ip_address():
    ip_address_path = 'secrets/ip_address.txt'
    address = open(ip_address_path,'r').read().rstrip()
    return address

def do_ssh(cmd):
    keyfile = io.StringIO(get_ssh_key())
    key = paramiko.RSAKey.from_private_key(keyfile)

    ssh = paramiko.SSHClient()

    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(get_ip_address(), username='ec2-user', pkey=key)

    stdin, stdout, stderr = ssh.exec_command(cmd)
    for line in stdout:
        print('... ' + line.strip('\n'))
        ssh.close()

def lambda_handler(event, context):
    cmd = "df -h"
    do_ssh(cmd)
    # print(get_ssh_key())
    return None

# def lambda_handler(event, context):
#     print("hello world, hookay?")

if __name__ == "__main__":
    lambda_handler(None, None)
