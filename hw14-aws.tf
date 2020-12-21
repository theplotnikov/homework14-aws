provider "aws" {
  region = "eu-west-1"
}

resource "aws_key_pair" "terr" {
  key_name   = "terr"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDb+vEhNfw1kH5VfYRPH2l8vdL8QTy/dbwddQI7IFxoYCqd4Oj9pg/ZPDooAlp3cqCsNNQWnaXGX05eLYlHwQF2abul0wzdEm8bXNu+QsIZ3KvoKNynPHwfqGvoB/0tyIqt6P37RKZemq0v7dlTlsJRswUnefbCX9jvgy5M3WOcK5qO7fU7CwtVulgsCBL4zqAFc0/zuljACCl2rpaeTGFjnWBUuAUvM1oZfDcKwWThO/sfy9nXctMy82xwJ6RfpijdEIxeiXDy9gv83v3qlD4rF+1Q3Mqdj8bEh+1NEwvcr8FvAgpZW53Uv1CuX58TEHqaRZWI4OiXmcFeG0ktuq8R root@terraform"
}

resource "aws_security_group" "allow" {
  name        = "allow"
  vpc_id      = "vpc-09141030bd07df142"

  ingress {
    description = "app to http"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "build" {
  ami = "ami-0dc8d444ee2a42d8a"
  instance_type = "t2.micro"
  key_name = "{aws_key_pair.terr.key_name}"
  vpc_security_group_ids = [aws_security_group.allow.id]
  subnet_id = "subnet-0a0186c3432342f6e"
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y openjdk-8-jdk maven awscli
git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git
cd boxfuse-sample-java-war-hello && mvn package
export AWS_ACCESS_KEY_ID=AKIAVB7HO5O23IY44UVQ
export AWS_SECRET_ACCESS_KEY=3MA7yhIAd16wIhddBA/Y2SashBZ4LJ1UHxSjma5B
export AWS_DEFAULT_REGION=eu-west-1
aws s3 cp target/hello-1.0.war s3://plotnikov
EOF
  tags = {
    Name = "build"
  }
}

resource "aws_instance" "deploy" {
  ami = "ami-0dc8d444ee2a42d8a"
  instance_type = "t2.micro"
  key_name = "{aws_key_pair.terr.key_name}"
  vpc_security_group_ids = [aws_security_group.allow.id]
  subnet_id = "subnet-04261f48b72aed719"
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y openjdk-8-jdk tomcat8 awscli
export AWS_ACCESS_KEY_ID=AKIAVB7HO5O23IY44UVQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=us-east-1
aws s3 cp s3://plotnikov/hello-1.0.war /tmp/hello-1.0.war
sudo mv /tmp/hello-1.0.war /var/lib/tomcat8/webapps/hello-1.0.war
sudo systemctl restart tomcat8
EOF
  tags = {
    Name = "deploy"
  }
}
