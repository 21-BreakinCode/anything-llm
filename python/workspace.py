import uuid
import json
from typing import Dict, List, Optional, Union, Any
from utils.api import APIClient, APIError


class Workspace:
    """
    A class to manage AnythingLLM workspaces with custom prompts.
    This class provides methods to create, update, and interact with workspaces.
    """

    def __init__(
        self,
        workspace_name: str,
        custom_prompt: str,
        temperature: float = 0.7,
        similarity_threshold: float = 0.7,
        history_count: int = 20,
        query_refusal_response: str = "I'm sorry, I cannot answer that question based on the available information.",
        chat_mode: str = "chat",
        top_n: int = 4,
        base_endpoint: str = "http://localhost:3001",
        api_key: str = None
    ):
        """
        Initialize a Workspace object with the given parameters.

        Args:
            workspace_name (str): Name of the workspace
            custom_prompt (str): Custom prompt for the workspace
            temperature (float, optional): Temperature for LLM responses. Defaults to 0.7.
            similarity_threshold (float, optional): Similarity threshold for vector search. Defaults to 0.7.
            history_count (int, optional): Number of history messages to keep. Defaults to 20.
            query_refusal_response (str, optional): Response when query is refused. Defaults to a standard message.
            chat_mode (str, optional): Chat mode (chat or query). Defaults to "chat".
            top_n (int, optional): Number of top results to return in vector search. Defaults to 4.
            base_endpoint (str, optional): Base API endpoint. Defaults to "http://localhost:3001".
            api_key (str, optional): API key for authentication. Defaults to None.
        """
        self.workspace_name = workspace_name
        self.custom_prompt = custom_prompt
        self.temperature = temperature
        self.similarity_threshold = similarity_threshold
        self.history_count = history_count
        self.query_refusal_response = query_refusal_response
        self.chat_mode = chat_mode
        self.top_n = top_n
        self.base_endpoint = base_endpoint.rstrip('/')
        self.api_key = api_key
        self.workspace_id = None
        self.workspace_slug = None

    def _get_api_client(self) -> APIClient:
        """
        Get an API client instance.

        Returns:
            APIClient: API client instance
        """
        return APIClient(base_endpoint=self.base_endpoint, api_key=self.api_key)

    def create(self) -> Dict[str, Any]:
        """
        Create a new workspace with the configured settings.

        Returns:
            Dict[str, Any]: Response from the API containing workspace details

        Raises:
            APIError: If the API request fails
        """
        endpoint = "v1/workspace/new"

        payload = {
            "name": self.workspace_name,
            "similarityThreshold": self.similarity_threshold,
            "openAiTemp": self.temperature,
            "openAiHistory": self.history_count,
            "openAiPrompt": self.custom_prompt,
            "queryRefusalResponse": self.query_refusal_response,
            "chatMode": self.chat_mode,
            "topN": self.top_n
        }

        api_client = self._get_api_client()
        data = api_client.post(endpoint, payload)

        if 'workspace' in data:
            self.workspace_id = data['workspace'].get('id')
            self.workspace_slug = data['workspace'].get('slug')

        return data

    def update(self) -> Dict[str, Any]:
        """
        Update an existing workspace with the current settings.

        Returns:
            Dict[str, Any]: Response from the API containing updated workspace details

        Raises:
            ValueError: If workspace slug is not set
            APIError: If the API request fails
        """
        if not self.workspace_slug:
            raise ValueError("Workspace slug is not set. Create a workspace first or set the slug manually.")

        endpoint = f"v1/workspace/{self.workspace_slug}/update"

        payload = {
            "name": self.workspace_name,
            "similarityThreshold": self.similarity_threshold,
            "openAiTemp": self.temperature,
            "openAiHistory": self.history_count,
            "openAiPrompt": self.custom_prompt,
            "queryRefusalResponse": self.query_refusal_response,
            "chatMode": self.chat_mode,
            "topN": self.top_n
        }

        api_client = self._get_api_client()
        return api_client.post(endpoint, payload)

    def delete(self) -> bool:
        """
        Delete the workspace.

        Returns:
            bool: True if deletion was successful

        Raises:
            ValueError: If workspace slug is not set
            APIError: If the API request fails
        """
        if not self.workspace_slug:
            raise ValueError("Workspace slug is not set. Cannot delete workspace.")

        endpoint = f"v1/workspace/{self.workspace_slug}"

        api_client = self._get_api_client()
        result = api_client.delete(endpoint)

        if result:
            self.workspace_id = None
            self.workspace_slug = None
            return True
        return False

    def get_details(self) -> Dict[str, Any]:
        """
        Get details of the workspace.

        Returns:
            Dict[str, Any]: Workspace details

        Raises:
            ValueError: If workspace slug is not set
            APIError: If the API request fails
        """
        if not self.workspace_slug:
            raise ValueError("Workspace slug is not set. Cannot get workspace details.")

        endpoint = f"v1/workspace/{self.workspace_slug}"

        api_client = self._get_api_client()
        return api_client.get(endpoint)

    def chat(self, message: str, session_id: str = None, attachments: List = None) -> Dict[str, Any]:
        """
        Send a chat message to the workspace.

        Args:
            message (str): Message to send
            session_id (str, optional): Session ID for chat continuity. Defaults to None.
            attachments (List, optional): List of attachments. Defaults to None.

        Returns:
            Dict[str, Any]: Response from the chat API

        Raises:
            ValueError: If workspace slug is not set
            APIError: If the API request fails
        """
        if not self.workspace_slug:
            raise ValueError("Workspace slug is not set. Cannot send chat message.")

        endpoint = f"v1/workspace/{self.workspace_slug}/chat"

        payload = {
            "message": message,
            "mode": self.chat_mode
        }

        if session_id:
            payload["sessionId"] = session_id

        if attachments:
            payload["attachments"] = attachments

        api_client = self._get_api_client()
        return api_client.post(endpoint, payload)

    def stream_chat(self, message: str, session_id: str = None, attachments: List = None):
        """
        Stream a chat message to the workspace.

        Args:
            message (str): Message to send
            session_id (str, optional): Session ID for chat continuity. Defaults to None.
            attachments (List, optional): List of attachments. Defaults to None.

        Yields:
            Dict[str, Any]: Streaming response chunks

        Raises:
            ValueError: If workspace slug is not set
            APIError: If the API request fails
        """
        if not self.workspace_slug:
            raise ValueError("Workspace slug is not set. Cannot stream chat message.")

        endpoint = f"v1/workspace/{self.workspace_slug}/stream-chat"

        payload = {
            "message": message,
            "mode": self.chat_mode
        }

        if session_id:
            payload["sessionId"] = session_id

        if attachments:
            payload["attachments"] = attachments

        api_client = self._get_api_client()
        yield from api_client.stream_post(endpoint, payload)

    def vector_search(self, query: str, top_n: int = None, score_threshold: float = None) -> Dict[str, Any]:
        """
        Perform a vector search in the workspace.

        Args:
            query (str): Search query
            top_n (int, optional): Number of results to return. Defaults to None (uses workspace setting).
            score_threshold (float, optional): Similarity threshold. Defaults to None (uses workspace setting).

        Returns:
            Dict[str, Any]: Search results

        Raises:
            ValueError: If workspace slug is not set
            APIError: If the API request fails
        """
        if not self.workspace_slug:
            raise ValueError("Workspace slug is not set. Cannot perform vector search.")

        endpoint = f"v1/workspace/{self.workspace_slug}/vector-search"

        payload = {
            "query": query
        }

        if top_n is not None:
            payload["topN"] = top_n

        if score_threshold is not None:
            payload["scoreThreshold"] = score_threshold

        api_client = self._get_api_client()
        return api_client.post(endpoint, payload)

    @classmethod
    def from_json(cls, json_data: Union[str, Dict], base_endpoint: str = "http://localhost:3001", api_key: str = None):
        """
        Create a Workspace object from JSON data.

        Args:
            json_data (Union[str, Dict]): JSON string or dictionary with workspace settings
            base_endpoint (str, optional): Base API endpoint. Defaults to "http://localhost:3001".
            api_key (str, optional): API key for authentication. Defaults to None.

        Returns:
            Workspace: A new Workspace object
        """
        if isinstance(json_data, str):
            data = json.loads(json_data)
        else:
            data = json_data

        # Required parameters
        workspace_name = data.get("workspace_name")
        custom_prompt = data.get("custom_prompt")

        if not workspace_name or not custom_prompt:
            raise ValueError("workspace_name and custom_prompt are required")

        # Optional parameters with defaults
        temperature = data.get("temperature", 0.7)
        similarity_threshold = data.get("similarity_threshold", 0.7)
        history_count = data.get("history_count", 20)
        query_refusal_response = data.get("query_refusal_response",
                                         "I'm sorry, I cannot answer that question based on the available information.")
        chat_mode = data.get("chat_mode", "chat")
        top_n = data.get("top_n", 4)

        return cls(
            workspace_name=workspace_name,
            custom_prompt=custom_prompt,
            temperature=temperature,
            similarity_threshold=similarity_threshold,
            history_count=history_count,
            query_refusal_response=query_refusal_response,
            chat_mode=chat_mode,
            top_n=top_n,
            base_endpoint=base_endpoint,
            api_key=api_key
        )

    def to_json(self) -> Dict[str, Any]:
        """
        Convert the workspace settings to a JSON-serializable dictionary.

        Returns:
            Dict[str, Any]: Dictionary with workspace settings
        """
        return {
            "workspace_name": self.workspace_name,
            "custom_prompt": self.custom_prompt,
            "temperature": self.temperature,
            "similarity_threshold": self.similarity_threshold,
            "history_count": self.history_count,
            "query_refusal_response": self.query_refusal_response,
            "chat_mode": self.chat_mode,
            "top_n": self.top_n
        }

    def __str__(self) -> str:
        """
        String representation of the workspace.

        Returns:
            str: String representation
        """
        return f"Workspace(name={self.workspace_name}, slug={self.workspace_slug}, id={self.workspace_id})"
