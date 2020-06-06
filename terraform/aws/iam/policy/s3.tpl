{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:ListBucket"
          ],
          "Resource": [
              "${bucket_arn}"
          ]
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:DeleteObject",
              "s3:PutObject*",
              "s3:GetObject"
          ],
          "Resource": [
              "${bucket_arn}/*"
          ]
      }
  ]
}