FROM python:3.10-slim

RUN apt-get update && apt-get install -y libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirement.txt .
RUN pip install -r requirement.txt
COPY . .

CMD ["gunicorn", "myapp.wsgi:application", "--bind", "0.0.0.0:8000"]
