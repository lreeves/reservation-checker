IAM Policy:

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
