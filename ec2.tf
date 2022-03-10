#ec2 role
resource "aws_iam_role" "iam_for_ec2_jenkins" {
  name = "JenkinsAccess"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

# IAM Policy for lambda 
resource "aws_iam_policy" "jenkins_access_policy" {
  name = "ec2-jenkins-policy"

  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Action" : [
          "codepipeline:AcknowledgeJob",
          "codepipeline:GetJobDetails",
          "codepipeline:PollForJobs",
          "codepipeline:PutJobFailureResult",
          "codepipeline:PutJobSuccessResult"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach_role" {
  role       = aws_iam_role.iam_for_ec2_jenkins.name
  policy_arn = aws_iam_policy.jenkins_access_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_server_profile" {
  name = "jenkins-server-profile"
  role = aws_iam_role.iam_for_ec2_jenkins.name
}

module "network" {
  source = "github.com/elvia-si/my_vpc_module"

  vpc_cidr         = "10.10.0.0/16"
  region           = "eu-west-1"
  vpc_name         = "my-VPC-for-practice"
  internet_gw_name = "my-internet-gateway"
  public_cidr_a    = "10.10.1.0/24"
  public_name      = "My-Public-A"
}

resource "aws_security_group" "jenkins_server_sg" {
  name        = "jenkins_server_sg"
  description = "Allow access to my jenkins server"
  vpc_id      = module.network.my_vpc_id

  # INBOUND RULES
  ingress {
    description = "SSH from my mac"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["87.10.254.4/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #   ingress {
  #     description = "HTTPS"
  #     from_port   = 443
  #     to_port     = 443
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }

  # OUTBOUND RULES
  egress {
    description = "Allow access to world"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG for jenkins server"
  }
}

data "aws_ami" "my_aws_ami" {
  owners      = ["137112412989"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }
}

resource "aws_instance" "my_jenkins_server" {
  ami                    = data.aws_ami.my_aws_ami.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.jenkins_server_profile.name
  key_name               = var.keypair_name
  subnet_id              = module.network.public_subnet_a_id
  vpc_security_group_ids = [aws_security_group.jenkins_server_sg.id]
}