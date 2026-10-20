import unittest
from unittest.mock import patch, MagicMock
import os
import sys

# Garante regiao padrao nos ambientes de CI/CD para evitar NoRegionError
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_REGION", "us-east-1")

# Adiciona o diretorio src/lambda_extracao ao path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src/lambda_extracao')))

import index

class TestLambdaExtracao(unittest.TestCase):

    def test_handler_sem_bucket_bronze_deve_lancar_erro(self):
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ValueError) as context:
                index.handler({}, {})
            self.assertIn("BUCKET_BRONZE nao configurada", str(context.exception))

    @patch('index.s3_client')
    def test_handler_com_bucket_executa_com_sucesso(self, mock_s3):
        with patch.dict(os.environ, {"BUCKET_BRONZE": "lumina-bronze-test"}):
            response = index.handler({}, {})
            self.assertEqual(response["statusCode"], 200)
            self.assertIn("Extracao finalizada", response["body"])
            # Garante que 2 arquivos foram gravados no S3 (semestral e mensal)
            self.assertEqual(mock_s3.put_object.call_count, 2)

    @patch('index.glue_client')
    @patch('index.s3_client')
    def test_handler_com_glue_job_dispara_start_job_run(self, mock_s3, mock_glue):
        mock_glue.start_job_run.return_value = {"JobRunId": "jr_test_12345"}
        with patch.dict(os.environ, {
            "BUCKET_BRONZE": "lumina-bronze-test",
            "GLUE_JOB_NAME": "lumina-bronze-to-silver-test"
        }):
            response = index.handler({}, {})
            self.assertEqual(response["statusCode"], 200)
            mock_glue.start_job_run.assert_called_once_with(JobName="lumina-bronze-to-silver-test")
            self.assertIn("jr_test_12345", response["body"])

    @patch('index.s3_client')
    def test_download_and_upload_to_s3_chama_put_object(self, mock_s3):
        index.download_and_upload_to_s3("http://exemplo.com/teste.csv", "meu-bucket", "caminho/arquivo.csv")
        mock_s3.put_object.assert_called_once()
        args, kwargs = mock_s3.put_object.call_args
        self.assertEqual(kwargs["Bucket"], "meu-bucket")
        self.assertEqual(kwargs["Key"], "caminho/arquivo.csv")

if __name__ == '__main__':
    unittest.main()

