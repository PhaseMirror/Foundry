import asyncio
import websockets
import json

async def test_deployment():
    uri = "ws://localhost:3002/ws"
    async with websockets.connect(uri) as websocket:
        print("--- Testing DEPLOY ---")
        await websocket.send("deploy web-service on cluster with 3 replicas")
        
        for _ in range(4):
            response = await websocket.recv()
            data = json.loads(response)
            print(f"<- {data['type'].upper()}: {data}")

        print("\n--- Testing REVOKE ---")
        await websocket.send("revoke it")

        for _ in range(4):
            response = await websocket.recv()
            data = json.loads(response)
            print(f"<- {data['type'].upper()}: {data}")

asyncio.run(test_deployment())
