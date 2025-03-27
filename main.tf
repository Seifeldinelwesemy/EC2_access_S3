provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc1" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "trial-vpc"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "IGW_trial_VPC"
  }
}


resource "aws_subnet" "public_sub" {
  cidr_block = "10.0.0.0/20"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.vpc1.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc1.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id = aws_subnet.public_sub.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_s3_bucket" "bucket" {
    bucket = "seif-bucket-16"
}

resource "aws_iam_role" "ec2_role" {
    name = "ec2_s3_access_role"

    assume_role_policy = jsonencode(
        {
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow",
            Action = "sts:AssumeRole"
            Principal = { 
                Service = "ec2.amazonaws.com" }
        }
    ]
    })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "EC2accessS3"
  policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Action = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      Effect = "Allow"
      Resource = ["arn:aws:s3:::${aws_s3_bucket.bucket.id}" ,
      "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"]
    }
  ]
}
  )
}


resource "aws_iam_role_policy_attachment" "attach_policy" {
  role = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


resource "aws_iam_instance_profile" "instance_profile" {
    name = "ec2_s3_profile"
    role = aws_iam_role.ec2_role.name
}


resource "aws_security_group" "secg" {
    vpc_id = aws_vpc.vpc1.id
  ingress {
    protocol = "tcp"
    cidr_blocks = ["102.184.145.247/32"]
    from_port = 22
    to_port = 22
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
}

resource "aws_instance" "server1" {
  ami = var.ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_sub.id
  vpc_security_group_ids = [aws_security_group.secg.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  key_name = "seif-new-key"
  tags = {
    Name = "first_instance"
  }
}
