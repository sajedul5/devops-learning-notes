FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Run as an unprivileged user instead of root.
RUN useradd --system --uid 1000 --no-create-home appuser   # uid 1000 matches the Helm chart runAsUser
USER appuser

EXPOSE 9001
CMD ["python3", "main.py"]
