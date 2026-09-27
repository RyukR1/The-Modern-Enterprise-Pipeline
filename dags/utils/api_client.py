import json
import logging
import time
from typing import Any, Dict, List, Optional
import requests
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

logger = logging.getLogger(__name__)


class APIClient:
    """
    Robust REST API extraction client with rate limiting, exponential backoff retries,
    and pagination support for raw data ingestion.
    """

    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        rate_limit_delay: float = 0.2,
        max_retries: int = 5,
        timeout: int = 30,
    ):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.rate_limit_delay = rate_limit_delay
        self.timeout = timeout
        self.session = requests.Session()

        # Configure exponential backoff retry strategy
        retries = Retry(
            total=max_retries,
            backoff_factor=1.5,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET"],
        )
        adapter = HTTPAdapter(max_retries=retries)
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)

        if self.api_key:
            self.session.headers.update({"Authorization": f"Bearer {self.api_key}"})
        self.session.headers.update({"Content-Type": "application/json"})

    def fetch_endpoint(self, endpoint: str, params: Optional[Dict[str, Any]] = None) -> Any:
        """
        Fetch data from a single API endpoint.
        """
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        logger.info(f"Fetching URL: {url} with params: {params}")

        time.sleep(self.rate_limit_delay)
        response = self.session.get(url, params=params, timeout=self.timeout)
        response.raise_for_status()
        return response.json()

    def fetch_paginated(
        self,
        endpoint: str,
        page_size: int = 100,
        max_pages: Optional[int] = None,
        params: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Fetch paginated records across multiple pages.
        """
        all_records: List[Dict[str, Any]] = []
        page = 1
        query_params = params.copy() if params else {}

        while True:
            query_params.update({"page": page, "limit": page_size})
            data = self.fetch_endpoint(endpoint, params=query_params)

            if isinstance(data, dict) and "data" in data:
                records = data["data"]
            elif isinstance(data, list):
                records = data
            else:
                records = []

            if not records:
                break

            all_records.extend(records)
            logger.info(f"Page {page}: Fetched {len(records)} records (Total: {len(all_records)})")

            if len(records) < page_size:
                break

            if max_pages and page >= max_pages:
                logger.info(f"Reached max pages limit of {max_pages}")
                break

            page += 1

        return all_records

    def save_as_ndjson(self, records: List[Dict[str, Any]], filepath: str) -> str:
        """
        Write records as NDJSON (Newline Delimited JSON) file suitable for Snowflake loading.
        """
        with open(filepath, "w", encoding="utf-8") as f:
            for record in records:
                f.write(json.dumps(record) + "\n")
        logger.info(f"Saved {len(records)} records to {filepath}")
        return filepath
