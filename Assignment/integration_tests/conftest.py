"""
Pytest configuration for integration tests.
"""

import time

import pytest
import requests

API_URL = "http://localhost:8000"


def is_api_available():
    """Check if the API server is running."""
    try:
        response = requests.get(f"{API_URL}/health", timeout=2)
        return response.status_code == 200
    except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
        return False


@pytest.fixture(scope="session", autouse=True)
def check_api_server():
    """
    Check if API server is running before running integration tests.
    Skip all tests if server is not available.
    """
    if not is_api_available():
        pytest.skip(
            "API server is not running at http://localhost:8000. "
            "Start the server before running integration tests:\n"
            "  uvicorn api_server:app --host 0.0.0.0 --port 8000",
            allow_module_level=True,
        )


@pytest.fixture(scope="session")
def api_url():
    """Provide the API URL to tests."""
    return API_URL


@pytest.fixture(scope="session")
def wait_for_api():
    """Wait for API to be ready."""
    max_retries = 10
    for i in range(max_retries):
        if is_api_available():
            return True
        time.sleep(1)
    pytest.fail("API did not become available in time")
