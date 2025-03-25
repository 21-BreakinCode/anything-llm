import json
import os
from typing import Dict, List, Optional, Union, Any
from workspace import Workspace
from utils.api import APIClient, APIError


class WorkspaceManager:
    """
    A class to manage multiple AnythingLLM workspaces.
    This class provides methods to create, load, and manage workspaces from JSON configurations.
    """

    def __init__(self, base_endpoint: str = "http://localhost:3001", api_key: str = None):
        """
        Initialize a WorkspaceManager object.

        Args:
            base_endpoint (str, optional): Base API endpoint. Defaults to "http://localhost:3001".
            api_key (str, optional): API key for authentication. Defaults to None.
        """
        self.base_endpoint = base_endpoint.rstrip('/')
        self.api_key = api_key
        self.workspaces = {}

    def create_workspace(self, config: Union[str, Dict]) -> Workspace:
        """
        Create a new workspace from a configuration.

        Args:
            config (Union[str, Dict]): JSON string or dictionary with workspace settings

        Returns:
            Workspace: The created workspace object
        """
        workspace = Workspace.from_json(config, self.base_endpoint, self.api_key)
        response = workspace.create()

        # Store the workspace in the manager
        self.workspaces[workspace.workspace_slug] = workspace

        return workspace

    def create_workspaces_from_json_file(self, file_path: str) -> List[Workspace]:
        """
        Create multiple workspaces from a JSON file.

        Args:
            file_path (str): Path to the JSON file containing workspace configurations

        Returns:
            List[Workspace]: List of created workspace objects
        """
        with open(file_path, 'r') as f:
            configs = json.load(f)

        if not isinstance(configs, list):
            configs = [configs]

        created_workspaces = []
        for config in configs:
            workspace = self.create_workspace(config)
            created_workspaces.append(workspace)

        return created_workspaces

    def get_workspace(self, slug: str) -> Optional[Workspace]:
        """
        Get a workspace by its slug.

        Args:
            slug (str): Workspace slug

        Returns:
            Optional[Workspace]: The workspace object if found, None otherwise
        """
        return self.workspaces.get(slug)

    def list_workspaces(self) -> List[Dict[str, Any]]:
        """
        List all workspaces from the API.

        Returns:
            List[Dict[str, Any]]: List of workspace details

        Raises:
            APIError: If the API request fails
        """
        api_client = APIClient(base_endpoint=self.base_endpoint, api_key=self.api_key)
        data = api_client.get("v1/workspaces")
        return data.get('workspaces', [])

    def load_workspaces(self) -> Dict[str, Workspace]:
        """
        Load all workspaces from the API and create Workspace objects.

        Returns:
            Dict[str, Workspace]: Dictionary of workspace objects keyed by slug
        """
        workspaces_data = self.list_workspaces()

        for workspace_data in workspaces_data:
            slug = workspace_data.get('slug')
            if slug and slug not in self.workspaces:
                # Create a workspace object with the data from the API
                workspace = Workspace(
                    workspace_name=workspace_data.get('name', ''),
                    custom_prompt=workspace_data.get('openAiPrompt', ''),
                    temperature=workspace_data.get('openAiTemp', 0.7),
                    similarity_threshold=workspace_data.get('similarityThreshold', 0.7),
                    history_count=workspace_data.get('openAiHistory', 20),
                    query_refusal_response=workspace_data.get('queryRefusalResponse', ''),
                    chat_mode=workspace_data.get('chatMode', 'chat'),
                    top_n=workspace_data.get('topN', 4),
                    base_endpoint=self.base_endpoint,
                    api_key=self.api_key
                )

                # Set the workspace ID and slug
                workspace.workspace_id = workspace_data.get('id')
                workspace.workspace_slug = slug

                # Add to the workspaces dictionary
                self.workspaces[slug] = workspace

        return self.workspaces

    def delete_workspace(self, slug: str) -> bool:
        """
        Delete a workspace by its slug.

        Args:
            slug (str): Workspace slug

        Returns:
            bool: True if deletion was successful
        """
        workspace = self.get_workspace(slug)
        if workspace:
            result = workspace.delete()
            if result:
                del self.workspaces[slug]
            return result
        return False

    def save_workspaces_to_json(self, file_path: str) -> None:
        """
        Save all workspaces to a JSON file.

        Args:
            file_path (str): Path to save the JSON file
        """
        configs = []
        for workspace in self.workspaces.values():
            configs.append(workspace.to_json())

        with open(file_path, 'w') as f:
            json.dump(configs, f, indent=2)

    def __str__(self) -> str:
        """
        String representation of the workspace manager.

        Returns:
            str: String representation
        """
        return f"WorkspaceManager(workspaces={len(self.workspaces)})"
