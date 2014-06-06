AWS Reservation Checker
=======================

This is a quick Ruby script to check your AWS reservations against running
instances. Currently it supports EC2, RDS and Elasticache instances, and
reservations of the "HEAVY" utilization type.

Usage
-----

Clone the repo and install the required Gems with bundler:

    git clone https://github.com/scoremedia/reservation-checker.git
    bundle

Copy the `config.yml.sample` to `config.yml` and customize it with the regions
and products you'd like to check and the AWS access keys you'd like to use.
Then just run the tool and view the gorgeous output:

    ./check.rb

    +---------------------------+---------------------+------------------+--------------------+-------------+
    | Type                      | Unused Reservations | Unreserved Units | Total Reservations | Total Units |
    +---------------------------+---------------------+------------------+--------------------+-------------+
    | ec2:c1.medium:us-east-1c  | 0                   | 1                | 0                  | 1           |
    | ec2:c1.medium:us-east-1d  | 0                   | 0                | 3                  | 3           |
    | ec2:c1.medium:us-east-1e  | 0                   | 1                | 0                  | 1           |
    | ec2:c1.xlarge:eu-west-1b  | 0                   | 0                | 1                  | 1           |
    | ec2:c1.xlarge:eu-west-1c  | 0                   | 1                | 2                  | 3           |
    | ec2:c1.xlarge:us-east-1a  | 0                   | 1                | 0                  | 1           |
    | ec2:c1.xlarge:us-east-1c  | 0                   | 0                | 3                  | 3           |
    | ec2:c1.xlarge:us-east-1d  | 2                   | 0                | 15                 | 13          |
    | ec2:c1.xlarge:us-east-1e  | 0                   | 1                | 7                  | 8           |
    | ec2:c3.2xlarge:us-east-1c | 0                   | 1                | 0                  | 1           |

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
            "ec2:DescribeReservedInstances",
            "elasticache:DescribeCacheClusters",
            "elasticache:DescribeReservedCacheNodes",
            "rds:DescribeDBInstances",
            "rds:DescribeReservedDBInstances"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
