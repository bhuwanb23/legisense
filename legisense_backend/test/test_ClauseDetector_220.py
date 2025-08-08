from django.test import TestCase
from rest_framework.test import APIClient


class TestClauseDetector(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_list(self):
        response = self.client.get('/api/')
        self.assertEqual(response.status_code, 200)

    def test_create(self):
        response = self.client.post('/api/', {})
        self.assertIn(response.status_code, [200, 201, 400])
