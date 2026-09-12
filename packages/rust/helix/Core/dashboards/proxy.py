"""
Local proxy server for Helix Constitutional Runtime Dashboard.
Relays requests to cloud endpoints and serves the dashboard HTML.
Run: python Z:\HELIX-CORE\dashboards\proxy.py
Then open: http://localhost:8765
"""
import json
import os
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler

AZURE_KEY = os.getenv("AZURE_FUNCTION_KEY", "")

ENDPOINTS = {
    "/proxy/gicd":  "https://gicd-scanner-231586465188.us-central1.run.app/gicd-scan",
    "/proxy/aws":   "https://erdmzd08ud.execute-api.us-east-1.amazonaws.com/default/helix-prime-4",
    "/proxy/azure": f"https://helix-memory-kernel.azurewebsites.net/api/memory?code={AZURE_KEY}",
}

DASHBOARD = open(os.path.join(os.path.dirname(__file__), "constitutional_runtime.html"), "rb").read()


class ProxyHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path == "/" or self.path == "/dashboard":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(DASHBOARD)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path not in ENDPOINTS:
            self.send_response(404)
            self.end_headers()
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        try:
            req = urllib.request.Request(
                ENDPOINTS[self.path],
                data=body,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = resp.read()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()


if __name__ == "__main__":
    server = HTTPServer(("localhost", 8765), ProxyHandler)
    print("Dashboard: http://localhost:8765")
    print("Press Ctrl+C to stop")
    server.serve_forever()
