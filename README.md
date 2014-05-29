AWS Reservation Checker
=======================

This is a quick Ruby script to check your AWS reservations against running
instances. Currently it only supports EC2 instances, and reservations of the
"HEAVY" utilization type.

IAM Policy
----------

The following policy can be used in the IAM console to provide a service
account access to the capabilities needed to poll reservations and resource
usage. It's strongly recommended you use this and not a key for anything else.

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Stmt1401308897000",
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeInstances",
            "ec2:DescribeReservedInstances"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
