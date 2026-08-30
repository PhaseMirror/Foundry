# Universal Closure Calculator — API web service
# Build context: repository root.
FROM python:3.11-slim

WORKDIR /app

# The API service lives in scripts/api/
COPY scripts/api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY scripts/api/main.py .

# Render injects $PORT; fall back to 8000 for local builds.
EXPOSE 8000
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
