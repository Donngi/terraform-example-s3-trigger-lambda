# ------------------------------------------------------------
# Lambda function
# ------------------------------------------------------------

data "archive_file" "transporter" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/upload/lambda.zip"
}

resource "aws_lambda_function" "transporter" {
  filename      = data.archive_file.transporter.output_path
  function_name = "DataTransporterTriggerByS3"
  role          = aws_iam_role.lambda_transporter.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.transporter.output_base64sha256

  runtime = "python3.8"

  tracing_config {
    mode = "Active"
  }

  timeout = 29
}

# ------------------------------------------------------------
# Resource policy
# ------------------------------------------------------------

resource "aws_lambda_permission" "transporter" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transporter.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
}

# ------------------------------------------------------------
# IAM Role
# ------------------------------------------------------------

resource "aws_iam_role" "lambda_transporter" {
  name = "SampleLambdaRole"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
        }
      ]
    }
  )
}

# Allow access to replica s3 bucket
resource "aws_iam_policy" "lambda_replica_s3_access" {
  name        = "LambdaReplicaS3AccessPolicy"
  description = "Allow lambda to access to specific s3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = var.replica_s3_arn
      },
      {
        Action = [
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_replica_s3_access" {
  role       = aws_iam_role.lambda_transporter.name
  policy_arn = aws_iam_policy.lambda_replica_s3_access.arn
}

# X-Ray
resource "aws_iam_policy" "lambda_xray" {
  name        = "LambdaTransporterXrayWriteOnlyPolicy"
  description = "Allow lambda to access to AWS X-Ray"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_transporter.name
  policy_arn = aws_iam_policy.lambda_xray.arn
}

# Basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_transporter.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
