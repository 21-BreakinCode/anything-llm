import requests
from typing import Dict, Any, Optional, Union


class APIError(Exception):
    """Exception raised for API errors."""

    def __init__(self, message: str, status_code: int = None, response_text: str = None):
        self.message = message
        self.status_code = status_code
        self.response_text = response_text
        super().__init__(self.message)


class APIClient:
    """
    A client for interacting with the AnythingLLM API.
    """

    def __init__(self, base_endpoint: str = "http://localhost:3001", api_key: str = None):
        """
        Initialize an APIClient object.

        Args:
            base_endpoint (str, optional): Base API endpoint. Defaults to "http://localhost:3001".
            api_key (str, optional): API key for authentication. Defaults to None.
        """
        self.base_endpoint = base_endpoint.rstrip('/')
        self.api_key = api_key

    def _get_headers(self) -> Dict[str, str]:
        """
        Get headers for API requests.

        Returns:
            Dict[str, str]: Headers dictionary
        """
        headers = {
            'Content-Type': 'application/json'
        }
        if self.api_key:
            headers['Authorization'] = f'Bearer {self.api_key}'
        return headers

    def get(self, endpoint: str, params: Dict = None) -> Dict[str, Any]:
        """
        Make a GET request to the API.

        Args:
            endpoint (str): API endpoint (without base URL)
            params (Dict, optional): Query parameters. Defaults to None.

        Returns:
            Dict[str, Any]: Response data

        Raises:
            APIError: If the request fails
        """
        # Prepend '/api' to the endpoint if it doesn't already start with '/api'
        if not endpoint.startswith('/api'):
            endpoint = f"/api/{endpoint.lstrip('/')}"

        url = f"{self.base_endpoint}/{endpoint.lstrip('/')}"

        try:
            print(f"Making GET request to: {url}")
            print(f"Headers: {self._get_headers()}")
            print(f"Params: {params}")

            response = requests.get(url, headers=self._get_headers(), params=params)
            print(f"Response status code: {response.status_code}")
            print(f"Response headers: {response.headers}")
            print(f"Response text: {response.text[:500]}...")

            response.raise_for_status()

            # Handle empty responses
            if not response.text.strip():
                print("Warning: Empty response received")
                return {}

            try:
                return response.json()
            except ValueError as json_err:
                print(f"JSON parsing error: {str(json_err)}")
                print(f"Raw response: {response.text}")
                raise APIError(f"Failed to parse JSON response: {str(json_err)}", response.status_code, response.text)

        except requests.exceptions.RequestException as e:
            status_code = getattr(e.response, 'status_code', None) if hasattr(e, 'response') else None
            response_text = getattr(e.response, 'text', None) if hasattr(e, 'response') else None
            print(f"Request exception: {str(e)}")
            print(f"Status code: {status_code}")
            print(f"Response text: {response_text}")
            raise APIError(f"GET request failed: {str(e)}", status_code, response_text)

    def post(self, endpoint: str, data: Dict = None) -> Dict[str, Any]:
        """
        Make a POST request to the API.

        Args:
            endpoint (str): API endpoint (without base URL)
            data (Dict, optional): Request body. Defaults to None.

        Returns:
            Dict[str, Any]: Response data

        Raises:
            APIError: If the request fails
        """
        # Prepend '/api' to the endpoint if it doesn't already start with '/api'
        if not endpoint.startswith('/api'):
            endpoint = f"/api/{endpoint.lstrip('/')}"

        url = f"{self.base_endpoint}/{endpoint.lstrip('/')}"

        try:
            print(f"Making POST request to: {url}")
            print(f"Headers: {self._get_headers()}")
            print(f"Data: {data}")

            response = requests.post(url, headers=self._get_headers(), json=data)
            print(f"Response status code: {response.status_code}")
            print(f"Response headers: {response.headers}")
            print(f"Response text: {response.text[:500]}...")

            response.raise_for_status()

            # Handle empty responses
            if not response.text.strip():
                print("Warning: Empty response received")
                return {}

            try:
                return response.json()
            except ValueError as json_err:
                print(f"JSON parsing error: {str(json_err)}")
                print(f"Raw response: {response.text}")
                raise APIError(f"Failed to parse JSON response: {str(json_err)}", response.status_code, response.text)

        except requests.exceptions.RequestException as e:
            status_code = getattr(e.response, 'status_code', None) if hasattr(e, 'response') else None
            response_text = getattr(e.response, 'text', None) if hasattr(e, 'response') else None
            print(f"Request exception: {str(e)}")
            print(f"Status code: {status_code}")
            print(f"Response text: {response_text}")
            raise APIError(f"POST request failed: {str(e)}", status_code, response_text)

    def delete(self, endpoint: str) -> Union[Dict[str, Any], bool]:
        """
        Make a DELETE request to the API.

        Args:
            endpoint (str): API endpoint (without base URL)

        Returns:
            Union[Dict[str, Any], bool]: Response data or True if successful with no content

        Raises:
            APIError: If the request fails
        """
        # Prepend '/api' to the endpoint if it doesn't already start with '/api'
        if not endpoint.startswith('/api'):
            endpoint = f"/api/{endpoint.lstrip('/')}"

        url = f"{self.base_endpoint}/{endpoint.lstrip('/')}"

        try:
            response = requests.delete(url, headers=self._get_headers())
            response.raise_for_status()

            # Some DELETE endpoints return no content
            if response.status_code == 204 or not response.text:
                return True

            return response.json()
        except requests.exceptions.RequestException as e:
            status_code = getattr(e.response, 'status_code', None)
            response_text = getattr(e.response, 'text', None)
            raise APIError(f"DELETE request failed: {str(e)}", status_code, response_text)

    def stream_post(self, endpoint: str, data: Dict = None):
        """
        Make a streaming POST request to the API.

        Args:
            endpoint (str): API endpoint (without base URL)
            data (Dict, optional): Request body. Defaults to None.

        Yields:
            Dict[str, Any]: Streaming response chunks

        Raises:
            APIError: If the request fails
        """
        import json

        # Prepend '/api' to the endpoint if it doesn't already start with '/api'
        if not endpoint.startswith('/api'):
            endpoint = f"/api/{endpoint.lstrip('/')}"

        url = f"{self.base_endpoint}/{endpoint.lstrip('/')}"

        try:
            response = requests.post(url, headers=self._get_headers(), json=data, stream=True)
            response.raise_for_status()

            for line in response.iter_lines():
                if line:
                    if line.startswith(b'data: '):
                        data = json.loads(line[6:])
                        yield data
                    else:
                        try:
                            yield json.loads(line)
                        except:
                            yield {"error": "Failed to parse response line"}
        except requests.exceptions.RequestException as e:
            status_code = getattr(e.response, 'status_code', None)
            response_text = getattr(e.response, 'text', None)
            raise APIError(f"Streaming POST request failed: {str(e)}", status_code, response_text)
