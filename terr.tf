
variable "bucket_site" {}
variable "region" {}
variable "route53_domain_name" {}
variable "route53_domain_zoneid" {}
variable "route53_domain_alias_name" {}
variable "route53_domain_alias_zoneid" {}


provider "aws" {
    region = "${var.region}"
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${aws_subnet.public.*.id}"]

  enable_deletion_protection = true

  access_logs {
    bucket  = "${aws_s3_bucket.lb_logs.bucket}"
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "${aws_iam_role.test_role.name}"

provisioner "remote-exec" {
    command = "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeInstance.ps1 -Schedule",
    interpreter = ["PowerShell"]
    connection {
      type     = "winrm"
      user     = "Administrator"
      password = "${var.admin_password}"
    }
  }
}



resource "aws_elb_attachment" "baz" {
  elb      = "${test-lb-tf.bar.id}"
  instance = "${test_profile.foo.id}"
}

resource "aws_s3_bucket" "site" {
    bucket = "${var.bucket_site}"
    acl = "public-read"
    policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.bucket_site}/*",
      "Principal": "*"
    }
  ]
}
EOF
    website {
        index_document = "index.html"
        error_document = "404.html"
    }
    tags {
    }
    force_destroy = true
}

resource "aws_route53_record" "domain" {
   name = "${var.route53_domain_name}"
   zone_id = "${var.route53_domain_zoneid}"
   type = "A"
   alias {
     name = "${var.route53_domain_alias_name}"
     zone_id = "${var.route53_domain_alias_zoneid}"
     evaluate_target_health = true
   }
}
resource "aws_iam_role" "ec2_s3_access_role" {
  name               = "s3-role"
  assume_role_policy = "${file("assumerolepolicy.json")}"
}

resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

