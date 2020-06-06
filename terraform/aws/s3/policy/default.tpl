{
  "Version": "2012-10-17",
  "Id": "policy-${bucket_name}",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Deny",
      "Action": "s3:*",
      "NotPrincipal": {
        "AWS": [
            "${user_arn}"
        ]
      }
      "Resource": [
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ],
      "Condition": {
        "StringNotLike": {
          "aws:userId": [
            "${iam_role_id}:*"
          ]
        }
      }
    }
  ]
}