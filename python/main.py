import json
import argparse
import sys
from typing import Dict, List, Any

from workspace import Workspace
from workspace_manager import WorkspaceManager
from create_role_workspaces import create_role_workspaces


def create_workspace_from_json(json_data: Dict[str, Any], base_endpoint: str, api_key: str = None) -> Workspace:
    """
    Create a workspace from JSON data.

    Args:
        json_data (Dict[str, Any]): JSON data with workspace settings
        base_endpoint (str): Base API endpoint
        api_key (str, optional): API key for authentication. Defaults to None.

    Returns:
        Workspace: Created workspace
    """
    manager = WorkspaceManager(base_endpoint=base_endpoint, api_key=api_key)
    return manager.create_workspace(json_data)


def create_workspaces_from_file(file_path: str, base_endpoint: str, api_key: str = None) -> List[Workspace]:
    """
    Create workspaces from a JSON file.

    Args:
        file_path (str): Path to JSON file
        base_endpoint (str): Base API endpoint
        api_key (str, optional): API key for authentication. Defaults to None.

    Returns:
        List[Workspace]: List of created workspaces
    """
    manager = WorkspaceManager(base_endpoint=base_endpoint, api_key=api_key)
    return manager.create_workspaces_from_json_file(file_path)


def list_workspaces(base_endpoint: str, api_key: str = None) -> List[Dict[str, Any]]:
    """
    List all workspaces.

    Args:
        base_endpoint (str): Base API endpoint
        api_key (str, optional): API key for authentication. Defaults to None.

    Returns:
        List[Dict[str, Any]]: List of workspace details
    """
    manager = WorkspaceManager(base_endpoint=base_endpoint, api_key=api_key)
    return manager.list_workspaces()


def main():
    """Main function to parse arguments and execute commands."""
    parser = argparse.ArgumentParser(description='AnythingLLM Workspace Manager')
    parser.add_argument('--endpoint', type=str, default='http://localhost:3001',
                        help='Base API endpoint (default: http://localhost:3001)')
    parser.add_argument('--api-key', type=str, help='API key for authentication')

    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # Create workspace from JSON string
    create_parser = subparsers.add_parser('create', help='Create a workspace from JSON')
    create_parser.add_argument('json', type=str, help='JSON string with workspace settings')

    # Create workspaces from JSON file
    create_file_parser = subparsers.add_parser('create-from-file', help='Create workspaces from JSON file')
    create_file_parser.add_argument('file', type=str, help='Path to JSON file')

    # List workspaces
    subparsers.add_parser('list', help='List all workspaces')

    # Create workspaces from roles directory
    subparsers.add_parser('create-from-roles', help='Create workspaces from all JSON files in the roles directory')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    try:
        match args.command:
            case 'create':
                json_data = json.loads(args.json)
                workspace = create_workspace_from_json(json_data, args.endpoint, args.api_key)
                print(f"Workspace created: {workspace}")
                print(json.dumps(workspace.to_json(), indent=2))

            case 'create-from-file':
                workspaces = create_workspaces_from_file(args.file, args.endpoint, args.api_key)
                print(f"Created {len(workspaces)} workspaces:")
                for workspace in workspaces:
                    print(f"- {workspace}")

            case 'list':
                workspaces = list_workspaces(args.endpoint, args.api_key)
                print(f"Found {len(workspaces)} workspaces:")
                for workspace in workspaces:
                    print(f"- {workspace['name']} (slug: {workspace['slug']})")

            case 'create-from-roles':
                workspaces = create_role_workspaces(args.endpoint, args.api_key)
                print(f"\nCreated {len(workspaces)} workspaces from role files.")

            case _:
                parser.print_help()

    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
