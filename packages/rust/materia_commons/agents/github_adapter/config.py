import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    GITHUB_WEBHOOK_SECRET = os.getenv("GITHUB_WEBHOOK_SECRET", "secret")
    GITHUB_ACCESS_TOKEN = os.getenv("GITHUB_ACCESS_TOKEN", "")
    MCP_HOST = os.getenv("MCP_HOST")  # e.g., "mcp-server"
    MCP_PORT = int(os.getenv("MCP_PORT", "8080")) if os.getenv("MCP_PORT") else None
    MCP_SERVER_CMD = os.getenv("MCP_SERVER_CMD", "cargo run -p multiplicity-mcp").split() if os.getenv("MCP_SERVER_CMD") else None
    EVALUATION_MODE = os.getenv("EVALUATION_MODE", "simulate")  # or "commit"
