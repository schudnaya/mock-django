FROM python:3.11-alpine

WORKDIR /app

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN apk add --no-cache gcc musl-dev postgresql-dev

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

WORKDIR /app/app

CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
