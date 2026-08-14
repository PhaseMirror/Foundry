FROM python:3.12-slim
WORKDIR /app
# We copy mcp_client first because it is referenced in requirements.txt as -e ../mcp_client
COPY agents/mcp_client /agents/mcp_client
COPY agents/github_adapter/requirements.txt .
# Modify requirements.txt to point to the absolute path during Docker build
RUN sed -i 's|-e ../mcp_client|-e /agents/mcp_client|g' requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY agents/github_adapter .
ENV PYTHONUNBUFFERED=1
CMD ["python", "run.py"]
