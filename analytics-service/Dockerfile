# --- Stage 1: Build (instala dependências em venv isolado) ---
FROM python:3.11-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Runtime ---
FROM python:3.11-slim

RUN useradd --create-home appuser
WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY . .

ENV PATH="/opt/venv/bin:$PATH"
USER appuser

EXPOSE 8005

# workers=1: o worker SQS roda em thread de background dentro do processo Flask.
# Mais de 1 worker gunicorn = múltiplos consumidores concorrentes da mesma fila.
CMD ["gunicorn", "--bind", "0.0.0.0:8005", "--workers", "1", "app:app"]
