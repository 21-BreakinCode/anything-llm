import os
import json
from typing import List, Dict, Any
from workspace import Workspace
from workspace_manager import WorkspaceManager

def get_role_files() -> List[str]:
    """
    Get all JSON files in the roles directory.

    Returns:
        List[str]: List of file paths
    """
    roles_dir = os.path.join(os.path.dirname(__file__), 'roles')
    if not os.path.exists(roles_dir):
        raise FileNotFoundError(f"Roles directory not found: {roles_dir}")

    role_files = []
    for filename in os.listdir(roles_dir):
        if filename.endswith('.json'):
            role_files.append(os.path.join(roles_dir, filename))

    return role_files

def create_role_workspaces(base_endpoint: str, api_key: str = None) -> List[Workspace]:
    """
    Create workspaces from all JSON files in the roles directory.

    Args:
        base_endpoint (str): Base API endpoint
        api_key (str, optional): API key for authentication. Defaults to None.

    Returns:
        List[Workspace]: List of created workspaces
    """
    manager = WorkspaceManager(base_endpoint=base_endpoint, api_key=api_key)
    role_files = get_role_files()

    if not role_files:
        print("No role files found in the roles directory.")
        return []

    created_workspaces = []
    for file_path in role_files:
        try:
            print(f"Creating workspace from {os.path.basename(file_path)}...")
            with open(file_path, 'r') as f:
                config = json.load(f)

            # Print the request payload for debugging
            print(f"  Request payload: {config}")

            workspace = manager.create_workspace(config)
            created_workspaces.append(workspace)
            print(f"✅ Created workspace: {workspace}")
        except Exception as e:
            print(f"❌ Error creating workspace from {file_path}: {str(e)}")
            # Print more detailed error information if available
            if hasattr(e, 'status_code') and hasattr(e, 'response_text'):
                print(f"  Status code: {e.status_code}")
                print(f"  Response: {e.response_text}")

    return created_workspaces

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Create workspaces from role files')
    parser.add_argument('--endpoint', type=str, default='http://localhost:3001',
                        help='Base API endpoint (default: http://localhost:3001)')
    parser.add_argument('--api-key', type=str, help='API key for authentication')

    args = parser.parse_args()

    workspaces = create_role_workspaces(args.endpoint, args.api_key)
    print(f"\nCreated {len(workspaces)} workspaces from role files.")
