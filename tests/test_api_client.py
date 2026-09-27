import os
import json
import pytest
from unittest.mock import patch, MagicMock
from dags.utils.api_client import APIClient


@pytest.fixture
def api_client():
    return APIClient(base_url="https://api.test.com", rate_limit_delay=0.0)


def test_fetch_endpoint_success(api_client):
    mock_response = MagicMock()
    mock_response.json.return_value = {"status": "ok", "data": [{"id": 1}]}
    mock_response.raise_for_status.return_value = None

    with patch.object(api_client.session, "get", return_value=mock_response) as mock_get:
        data = api_client.fetch_endpoint("users")
        assert data["status"] == "ok"
        mock_get.assert_called_once()


def test_fetch_paginated(api_client):
    mock_response_1 = MagicMock()
    mock_response_1.json.return_value = [{"id": 1}, {"id": 2}]
    mock_response_1.raise_for_status.return_value = None

    mock_response_2 = MagicMock()
    mock_response_2.json.return_value = []
    mock_response_2.raise_for_status.return_value = None

    with patch.object(api_client.session, "get", side_effect=[mock_response_1, mock_response_2]):
        records = api_client.fetch_paginated("users", page_size=2)
        assert len(records) == 2
        assert records[0]["id"] == 1


def test_save_as_ndjson(api_client, tmp_path):
    records = [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]
    target_file = tmp_path / "test_records.json"

    api_client.save_as_ndjson(records, str(target_file))

    assert os.path.exists(target_file)
    with open(target_file, "r") as f:
        lines = f.readlines()
        assert len(lines) == 2
        assert json.loads(lines[0])["name"] == "Alice"
