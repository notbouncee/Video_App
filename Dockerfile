FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    ffmpeg\
    curl\
    && rm -rf /var/lib/apt/lists/*

# Install poetry 
RUN pip install poetry

# Copy poetry configuration files
COPY pyproject.toml poetry.lock* /app/

# Configure poetry to not create a virtual environment
RUN poetry config virtualenvs.create false

# Install dependencies (only production deps, no project installation)
RUN poetry install --only main --no-root

COPY src/ /app/src/

COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh 

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]

# Command to run the application
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]