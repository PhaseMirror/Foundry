import asyncio
import json
import logging
from dataclasses import dataclass
from typing import Optional, Literal

logger = logging.getLogger(__name__)

EvaluationMode = Literal["simulate", "commit"]

@dataclass
class TransitionRequest:
    agent_request_id: str
    transition_data: dict  # must match sigma::StateTransition serialization
    mode: EvaluationMode

@dataclass
class TransitionResponse:
    status: str  # "ratified", "simulated", "dissonance_trap"
    witness_id: Optional[str] = None
    ratified_block: Optional[dict] = None
    breach_type: Optional[str] = None
    details: Optional[str] = None
    conflict_log_id: Optional[str] = None

class SigmaMCPClient:
    def __init__(self, host: str = None, port: int = None, server_cmd: list[str] = None):
        """
        Connect to the MCP server either via TCP (host+port) or by spawning a subprocess (server_cmd).
        If host and port are given, TCP mode is used; otherwise server_cmd is used.
        """
        self.host = host
        self.port = port
        self.server_cmd = server_cmd
        self._process = None
        self._reader = None
        self._writer = None

    async def __aenter__(self):
        if self.host and self.port:
            # TCP mode
            self._reader, self._writer = await asyncio.open_connection(self.host, self.port)
            logger.info(f"Connected to MCP server at {self.host}:{self.port}")
        elif self.server_cmd:
            # stdio subprocess mode
            self._process = await asyncio.create_subprocess_exec(
                *self.server_cmd,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            self._reader = self._process.stdout
            self._writer = self._process.stdin
            logger.info(f"Spawned MCP server: {' '.join(self.server_cmd)}")
        else:
            raise ValueError("Either host/port or server_cmd must be provided")
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self._writer:
            self._writer.close()
            await self._writer.wait_closed()
        if self._process:
            self._process.terminate()
            await self._process.wait()

    async def evaluate_transition(self, request: TransitionRequest) -> TransitionResponse:
        # Build JSON-RPC request
        rpc_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": "evaluate_transition",
                "arguments": {
                    "agent_request_id": request.agent_request_id,
                    "transition_data": request.transition_data,
                    "mode": request.mode,
                }
            }
        }
        request_line = json.dumps(rpc_request) + "\n"

        # Send
        self._writer.write(request_line.encode())
        await self._writer.drain()

        # Read response (one line)
        response_line = await self._reader.readline()
        if not response_line:
            raise ConnectionError("MCP server closed connection")
        response_json = json.loads(response_line)

        # Check for JSON-RPC error
        if "error" in response_json:
            error = response_json["error"]
            raise RuntimeError(f"JSON-RPC error {error.get('code')}: {error.get('message')}")

        # Extract result
        result = response_json.get("result")
        if not result:
            raise RuntimeError("Missing 'result' in response")

        return TransitionResponse(
            status=result["status"],
            witness_id=result.get("witness_id"),
            ratified_block=result.get("ratified_block"),
            breach_type=result.get("breach_type"),
            details=result.get("details"),
            conflict_log_id=result.get("conflict_log_id"),
        )
