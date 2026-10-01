terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# IAM Role pre-existente da AWS Academy Learner Lab
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ==============================================================================
# 1. Lambda de Extracao SISAGUA
# ==============================================================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambda_extracao"
  output_path = "${path.module}/dist/lambda_extracao.zip"
  excludes    = ["__pycache__", "*.pyc", ".pytest_cache"]
}

resource "aws_lambda_function" "extracao_sisagua" {
  function_name    = "${var.project_name}-extracao-sisagua-${var.environment}"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 120
  memory_size      = 256

  environment {
    variables = {
      BUCKET_BRONZE = var.bucket_bronze_name
      TZ            = "America/Sao_Paulo"
    }
  }

  tags = {
    Projeto   = "Lumina Odontológica"
    Component = "Data Pipeline - Lambda Extracao"
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.extracao_sisagua.function_name}"
  retention_in_days = 7
}

# Agendamento Cron para execucao diaria da Lambda
resource "aws_cloudwatch_event_rule" "cron" {
  name                = "${var.project_name}-extracao-cron-${var.environment}"
  description         = "Trigger diario para extracao SISAGUA"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.cron.name
  target_id = "TargetLambdaExtracao"
  arn       = aws_lambda_function.extracao_sisagua.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.extracao_sisagua.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron.arn
}

# ==============================================================================
# 2. Script e Job AWS Glue (Bronze -> Silver)
# ==============================================================================

resource "aws_s3_object" "glue_script" {
  bucket      = var.script_bucket_id
  key         = "scripts/${var.project_name}-bronze-to-silver-${var.environment}.py"
  source      = "${path.module}/../src/glue_transformacao/job.py"
  source_hash = filemd5("${path.module}/../src/glue_transformacao/job.py")
}

resource "aws_glue_job" "job" {
  name     = "${var.project_name}-bronze-to-silver-${var.environment}"
  role_arn = data.aws_iam_role.lab_role.arn

  command {
    script_location = "s3://${aws_s3_object.glue_script.bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--JOB_NAME"      = "${var.project_name}-bronze-to-silver-${var.environment}"
    "--BUCKET_BRONZE" = "s3://${var.bucket_bronze_name}"
    "--BUCKET_SILVER" = "s3://${var.bucket_silver_name}"
  }

  glue_version      = var.glue_version
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers

  tags = {
    Projeto   = "Lumina Odontológica"
    Component = "Data Pipeline - Glue Job"
  }
}

# EventBridge Trigger quando objeto e gravado no S3 Bronze
resource "aws_cloudwatch_event_rule" "s3_trigger" {
  count       = var.enable_s3_trigger ? 1 : 0
  name        = "${var.project_name}-glue-s3-trigger-${var.environment}"
  description = "Dispara Glue Job quando arquivos forem gravados no bucket Bronze"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : {
        "name" : [var.bucket_bronze_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "glue_target" {
  count    = var.enable_s3_trigger ? 1 : 0
  rule     = aws_cloudwatch_event_rule.s3_trigger[0].name
  arn      = aws_glue_job.job.arn
  role_arn = data.aws_iam_role.lab_role.arn
}
