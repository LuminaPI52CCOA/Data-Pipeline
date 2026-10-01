output "lambda_extracao_arn" {
  value       = aws_lambda_function.extracao_sisagua.arn
  description = "ARN da funcao Lambda de extracao SISAGUA"
}

output "lambda_extracao_name" {
  value       = aws_lambda_function.extracao_sisagua.function_name
  description = "Nome da funcao Lambda de extracao SISAGUA"
}

output "glue_job_name" {
  value       = aws_glue_job.job.name
  description = "Nome do AWS Glue Job de transformacao"
}

output "glue_job_arn" {
  value       = aws_glue_job.job.arn
  description = "ARN do AWS Glue Job de transformacao"
}
