import unittest
from unittest.mock import patch, MagicMock
import os
import sys

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

    @patch('index.s3_client')
    def test_download_and_upload_to_s3_chama_put_object(self, mock_s3):
        index.download_and_upload_to_s3("http://exemplo.com/teste.csv", "meu-bucket", "caminho/arquivo.csv")
        mock_s3.put_object.assert_called_once()
        args, kwargs = mock_s3.put_object.call_args
        self.assertEqual(kwargs["Bucket"], "meu-bucket")
        self.assertEqual(kwargs["Key"], "caminho/arquivo.csv")

if __name__ == '__main__':
    unittest.main()
