# Data-Pipeline — Lumina Odontológica

Pipeline de Engenharia de Dados (ETL / Data Lakehouse) do ecossistema **Lumina**, responsável por ingerir, transformar e analisar dados públicos de qualidade da água (SISAGUA) para correlação com parâmetros de saúde bucal (níveis de fluoreto na água de abastecimento público).

---

## 1. Arquitetura da Pipeline (Medallion Architecture)

```text
[SISAGUA API / Dados Públicos]
         │
         ▼ (Cron Diário às 03:00 via Amazon EventBridge)
[AWS Lambda: lumina-extracao-sisagua] (Python 3.11)
         │
         ▼ (Grava JSON/CSV brutos com particionamento temporal)
[S3 Bucket: lumina-bronze]
         │
         ▼ (Trigger EventBridge: s3:ObjectCreated)
[AWS Glue Job: lumina-bronze-to-silver] (Apache Spark / PySpark)
         │
         ▼ (Limpeza, tipagem, filtro Santo André e conversão para Parquet)
[S3 Bucket: lumina-silver]
         │
         ▼ (Crawler do AWS Glue catálogo de dados)
[AWS Glue Data Catalog + Amazon Athena] ➔ [S3 Bucket: lumina-athena-results]
         │
         ▼ (Consultas analíticas e correlação com incidência de cáries/fluorose)
[Power BI / Dashboard Lumina]
```

---

## 2. Estrutura do Repositório

```text
Data-Pipeline/
├── .github/
│   └── workflows/
│       ├── data-pipeline-ci.yml    # CI: Lint e Testes Unitários automatizados
│       └── data-pipeline-cd.yml    # CD: Deploy de scripts Python/Spark no S3 sem recriar infra
├── src/
│   ├── lambda_extracao/            # Código da Lambda de extração (Python 3.11)
│   └── glue_transformacao/         # Script PySpark do Glue Job
├── test/                           # Testes unitários com unittest / pytest
├── terraform/                      # Módulo Terraform com S3, Glue, Lambda e Athena
├── requirements.txt                # Dependências Python (boto3, pandas, pyspark, etc.)
└── README.md
```

---

## 3. Ambientes e Execução na Infraestrutura

A pipeline foi desacoplada da infraestrutura web principal para garantir flexibilidade e economia de recursos no AWS Academy Learner Lab:

* **Ambiente `dev`:** A pipeline de dados **não roda em dev** para evitar custos e acelerar a subida das instâncias da API.
* **Ambiente `prod`:** Ativa e provisionada em conjunto com os 7 nós da infraestrutura para a apresentação final.
* **Ambiente `data` (Isolado):** Provisionável autonomamente no repositório `Infraestrutura` através do workflow dedicado do GitHub Actions **Data Pipeline Deploy/Destroy**, permitindo testar a ingestão, o Glue Job e o Athena sem ligar instâncias EC2 de backend ou frontend.

---

## 4. Testes Locais

Para executar os testes unitários da Lambda e dos scripts de transformação:

```bash
python3 -m unittest discover -s test -v
```
