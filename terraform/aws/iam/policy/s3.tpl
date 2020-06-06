{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:ListBucket"
          ],
          "Resource": [
              "arn:aws:s3:::${bucket_name}"
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
              "arn:aws:s3:::${bucket_name}/*"
          ]
      }
  ]
}