#######
# IAM
#######

resource "aws_iam_role" "ssh_access_lambda" {
    name = "${var.name}"
    path = "/"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
              "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ssh_access_lambda" {
  name = "${var.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",

        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "ssh_access_lambda" {
    name = "${var.name}"
    roles = ["${aws_iam_role.ssh_access_lambda.name}"]
    policy_arn = "${aws_iam_policy.ssh_access_lambda.arn}"
}


#####################
# CW trigger
#####################

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id   = "AllowExecutionFromCloudWatch"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.ssh_access_lambda.function_name}"
  principal      = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "ssh_access_lambda" {
  name                = "${var.name}"
  schedule_expression = "${var.schedule}"
}

resource "aws_cloudwatch_event_target" "ssh_access_lambda" {
  rule      = "${aws_cloudwatch_event_rule.ssh_access_lambda.name}"
  arn       = "${aws_lambda_function.ssh_access_lambda.arn}"
}

#####################
# INSTANCE (+ ssh key)
#####################

# https://github.com/cloudposse/terraform-aws-key-pair
# outputs: key_name, public_key
module "ssh_access_key_pair" {
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=master"
  namespace             = "${var.name}"
  stage                 = "env"
  name                  = "${var.name}"
  ssh_public_key_path   = "code/secrets"
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
}

# access me from lambda...
resource "aws_instance" "web" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"
  subnet_id     = "${var.vpc_subnet_id}"
  key_name      = "${module.ssh_access_key_pair.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]

  tags {
    Name = "ssh_access_lambda"
  }

  # after creation, save ip + generated ssh key to the lambda package.
  # going to read ssh key (need perm) + run ssh via paramiko.
  # data "archive_file" {} does not work well with virtualenv symlinks - so using sh zip.
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.private_ip} > code/secrets/ip_address.txt && chmod 777 code/secrets/*pem && bash zip_lambda_code.sh"
  }
}

############################
# Securitah group allow ssh
############################

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow all inbound traffic"

  # still bound to the specific vpc.
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6" # tcp
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 22
    to_port         = 22
    protocol        = "6" # tcp
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#####################
# LAMBDA
#####################

resource "aws_lambda_function" "ssh_access_lambda" {
  filename         = "ssh_access_lambda.zip"
  runtime          = "python3.6"
  function_name    = "${var.name}"
  role             = "${aws_iam_role.ssh_access_lambda.arn}"
  handler          = "main.lambda_handler"

  # maximum. can tweakme.
  timeout          = 300

  source_code_hash = "${base64sha256(file("ssh_access_lambda.zip"))}"

  publish          = true
  vpc_config {
    subnet_ids = ["${var.vpc_subnet_id}"]
    security_group_ids = ["${aws_security_group.allow_ssh.id}"]

  }

  # only create lambda at the end after the other stuff above.
  depends_on = ["aws_iam_policy_attachment.ssh_access_lambda", "aws_instance.web"]
}
