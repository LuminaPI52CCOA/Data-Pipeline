# Data-Pipeline — Lumina Odontológica

Pipeline de Engenharia de Dados (ETL / Data Lake) do sistema **Lumina**, responsável por ingerir, processar e transformar dados públicos de qualidade da água (SISAGUA) para análise de parâmetros odontológicos (níveis de fluoreto).

---

## 1. Arquitetura da Pipeline

```text
[SISAGUA API / CSVs]
         │
         ▼ (Cron Diário às 03:00 - EventBridge)
[AWS Lambda: lumina-extracao-sisagua]
         │
         ▼ (Salva dados brutos)
[S3 Bucket: lumina-bronze]
         │
         ▼ (EventBridge: Object Created)
[AWS Glue Job: lumina-bronze-to-silver] (PySpark)
         │
         ▼ (Filtra Santo André & Fluoreto e converte para Parquet)
[S3 Bucket: lumina-silver]
```

---

## 2. Estrutura do Repositório

```text
Data-Pipeline/
├── .github/
│   └── workflows/
│       ├── data-pipeline-ci.yml    # CI: Lint e Testes Unitários
│       └── data-pipeline-cd.yml    # CD: Deploy rápido de código sem recriar infra
├── src/
│   ├── lambda_extracao/            # Código da Lambda de extração (Python 3.11)
│   └── glue_transformacao/         # Script PySpark do Glue Job
├── test/                           # Testes unitários com unittest / pytest
├── terraform/                      # Módulo Terraform oficial consumido pela Infraestrutura
├── requirements.txt
└── README.md
```

---

## 3. Executando os Testes Localmente

```bash
python3 -m unittest discover -s test -v
```

---

## 4. Integração com a Infraestrutura

Este repositório expõe o módulo Terraform em `terraform/`, instanciado pelo repositório central [`Infraestrutura`](../Infraestrutura) nos ambientes `dev` e `prod`.
