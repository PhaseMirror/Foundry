FROM public.ecr.aws/lambda/python:3.11
COPY requirements.txt .
RUN pip install --no-cache-dir --only-binary=:all: -r requirements.txt
COPY pikernel/ ./pikernel/
COPY app.py .
ENV AWS_LAMBDA_FUNCTION_HANDLER=app.handler
CMD [ "app.handler" ]
