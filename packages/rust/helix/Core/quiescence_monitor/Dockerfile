FROM python:3.11-alpine
WORKDIR /app
COPY monitor.py .
RUN pip install pyyaml
RUN chmod +x monitor.py
CMD ["python", "monitor.py"]
