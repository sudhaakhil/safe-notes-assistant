# Isolated, disposable environment for the offline demo.
# The image holds its own copy of the project; nothing from your PC is mounted.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
# Run as an unprivileged user that owns only /app.
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["python", "app.py"]
CMD ["--mode", "offline"]
