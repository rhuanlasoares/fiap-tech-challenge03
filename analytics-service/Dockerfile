FROM python:3.13.13-alpine AS builder

WORKDIR /app

# RUN apt-get update && apt-get upgrade -y && \
#     apt-get install -y --no-install-recommends && \
#     rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.13.13-alpine AS production

RUN adduser -D -s /bin/sh appuser

RUN apk update && apk upgrade --no-cache

WORKDIR /app

# RUN apt-get update && apt-get upgrade -y && \
#     rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser app.py app.py

ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER appuser

EXPOSE 8005

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8005/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8005", "app:app"]
