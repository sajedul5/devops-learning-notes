FROM python:3.12-alpine

WORKDIR /code

# Install dependencies first so this layer is cached between code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Run as an unprivileged user instead of root.
RUN adduser -D -H appuser
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
