# AnythingLLM Workspace Manager

A Python library for creating and managing AnythingLLM workspaces with custom prompts.

## Features

- Create workspaces with custom prompts and settings
- Update existing workspaces
- Delete workspaces
- Chat with workspaces
- Perform vector searches
- Stream chat responses
- Load and save workspace configurations from/to JSON

## Installation

1. Make sure you have Python 3.6+ installed
2. Install the required dependencies:

```bash
pip install requests
```

## Usage

### Creating a Workspace

```python
from python import Workspace

# Create a workspace with custom prompt
workspace = Workspace(
    workspace_name="My Custom Workspace",
    custom_prompt="You are a helpful assistant that specializes in technology.",
    temperature=0.7,
    base_endpoint="http://localhost:3001",
    api_key="your-api-key"  # Optional
)

# Create the workspace on the server
result = workspace.create()
print(f"Workspace created: {workspace}")
```

### Creating a Workspace from JSON

```python
from python import Workspace

# JSON configuration
config = {
    "workspace_name": "My JSON Workspace",
    "custom_prompt": "You are a helpful assistant that specializes in finance.",
    "temperature": 0.5,
    "similarity_threshold": 0.8,
    "history_count": 10
}

# Create workspace from JSON
workspace = Workspace.from_json(
    config,
    base_endpoint="http://localhost:3001",
    api_key="your-api-key"  # Optional
)

# Create the workspace on the server
result = workspace.create()
print(f"Workspace created: {workspace}")
```

### Managing Multiple Workspaces

```python
from python import WorkspaceManager

# Create a workspace manager
manager = WorkspaceManager(
    base_endpoint="http://localhost:3001",
    api_key="your-api-key"  # Optional
)

# Create workspaces from a JSON file
workspaces = manager.create_workspaces_from_json_file("workspaces.json")

# List all workspaces
all_workspaces = manager.list_workspaces()
print(f"Found {len(all_workspaces)} workspaces")

# Load existing workspaces
loaded_workspaces = manager.load_workspaces()

# Get a specific workspace
workspace = manager.get_workspace("my-workspace-slug")

# Delete a workspace
manager.delete_workspace("my-workspace-slug")

# Save workspace configurations to a JSON file
manager.save_workspaces_to_json("saved_workspaces.json")
```

### Chatting with a Workspace

```python
from python import Workspace

# Create or load a workspace
workspace = Workspace(
    workspace_name="My Workspace",
    custom_prompt="You are a helpful assistant.",
    base_endpoint="http://localhost:3001"
)
workspace.workspace_slug = "my-workspace-slug"  # Set if loading existing

# Send a chat message
response = workspace.chat("What is AnythingLLM?")
print(response["textResponse"])

# Stream a chat message
for chunk in workspace.stream_chat("Tell me about vector databases"):
    if chunk.get("textResponse"):
        print(chunk["textResponse"], end="", flush=True)
    if chunk.get("close", False):
        print("\n\nSources:", chunk.get("sources", []))
```

### Performing Vector Search

```python
from python import Workspace

# Create or load a workspace
workspace = Workspace(
    workspace_name="My Workspace",
    custom_prompt="You are a helpful assistant.",
    base_endpoint="http://localhost:3001"
)
workspace.workspace_slug = "my-workspace-slug"  # Set if loading existing

# Perform a vector search
results = workspace.vector_search("What is AnythingLLM?")
for result in results.get("results", []):
    print(f"Score: {result['score']}")
    print(f"Text: {result['text'][:100]}...")
    print(f"Source: {result['metadata']['title']}")
    print("---")
```

## Command Line Interface

The package includes a command-line interface for basic operations. There are two ways to run the commands:

### Using the Makefile (Recommended)

The Makefile handles the Python module imports correctly:

```bash
# Create workspaces from all JSON files in the roles directory
make -f Makefile-python create-roles ENDPOINT=https://your-endpoint API_KEY=your-api-key

# List all workspaces
make -f Makefile-python list-workspaces ENDPOINT=https://your-endpoint API_KEY=your-api-key

# Create a workspace from JSON string
make -f Makefile-python create-workspace JSON='{"workspace_name":"CLI Workspace","custom_prompt":"You are a helpful assistant."}' ENDPOINT=https://your-endpoint API_KEY=your-api-key

# Create workspaces from a JSON file
make -f Makefile-python create-from-file FILE=workspaces.json ENDPOINT=https://your-endpoint API_KEY=your-api-key
```

### Using Python Module Syntax

If you prefer to use Python directly, you need to use the module syntax:

```bash
# Create a workspace from JSON string
cd python && python -m main --endpoint https://your-endpoint --api-key your-api-key create '{"workspace_name": "CLI Workspace", "custom_prompt": "You are a helpful assistant."}'

# Create workspaces from a JSON file
cd python && python -m main --endpoint https://your-endpoint --api-key your-api-key create-from-file workspaces.json

# List all workspaces
cd python && python -m main --endpoint https://your-endpoint --api-key your-api-key list

# Create workspaces from all JSON files in the roles directory
cd python && python -m main --endpoint https://your-endpoint --api-key your-api-key create-from-roles

# Without API key (only works if AnythingLLM doesn't require authentication)
cd python && python -m main --endpoint https://your-endpoint list
```

## JSON Configuration Format

The JSON configuration for workspaces should follow this format:

```json
{
  "workspace_name": "My Workspace",
  "custom_prompt": "You are a helpful assistant specialized in...",
  "temperature": 0.7,
  "similarity_threshold": 0.7,
  "history_count": 20,
  "query_refusal_response": "I'm sorry, I cannot answer that question based on the available information.",
  "chat_mode": "chat",
  "top_n": 4
}
```

For multiple workspaces, use an array of workspace configurations:

```json
[
  {
    "workspace_name": "Workspace 1",
    "custom_prompt": "You are a helpful assistant specialized in technology."
  },
  {
    "workspace_name": "Workspace 2",
    "custom_prompt": "You are a helpful assistant specialized in finance."
  }
]
```

## Required and Optional Fields

- Required fields:
  - `workspace_name`: Name of the workspace
  - `custom_prompt`: Custom prompt for the workspace

- Optional fields (with defaults):
  - `temperature`: Temperature for LLM responses (default: 0.7)
  - `similarity_threshold`: Similarity threshold for vector search (default: 0.7)
  - `history_count`: Number of history messages to keep (default: 20)
  - `query_refusal_response`: Response when query is refused (default: "I'm sorry, I cannot answer that question based on the available information.")
  - `chat_mode`: Chat mode (default: "chat")
  - `top_n`: Number of top results to return in vector search (default: 4)
