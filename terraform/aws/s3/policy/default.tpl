{
  "Version": "2012-10-17",
  "Id": "Deny policy",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Deny",
      "Action": "s3:*",
      "NotPrincipal": {
        "AWS": [
          "${user_arn}"
        ]
      },
      "Resource": [
        "${bucket_arn}",
        "${bucket_arn}/*"
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