variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Regiao da AWS"
}

variable "project_name" {
  type        = string
  default     = "lumina"
  description = "Prefixo de identificacao do projeto"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Ambiente de execucao (dev ou prod)"
}

variable "bucket_bronze_name" {
  type        = string
  description = "Nome do Bucket S3 da camada Bronze"
}

variable "bucket_silver_name" {
  type        = string
  description = "Nome do Bucket S3 da camada Silver"
}

variable "script_bucket_id" {
  type        = string
  description = "ID do Bucket S3 onde o script Python do Glue sera armazenado"
}

variable "schedule_expression" {
  type        = string
  default     = "cron(0 3 * * ? *)"
  description = "Expressao cron para execucao da Lambda de extracao"
}

variable "enable_s3_trigger" {
  type        = bool
  default     = true
  description = "Habilitar disparo automatico do Glue Job a partir de eventos do S3 Bronze"
}

variable "glue_version" {
  type        = string
  default     = "4.0"
  description = "Versao do AWS Glue"
}

variable "worker_type" {
  type        = string
  default     = "G.1X"
  description = "Tipo de worker do AWS Glue"
}

variable "number_of_workers" {
  type        = number
  default     = 2
  description = "Quantidade de workers do Glue Job"
}
