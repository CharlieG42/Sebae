FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends     build-essential     && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create directory for reports
RUN mkdir -p reports

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DB_TYPE=sqlite
ENV DB_PATH=/app/sebae.db

# Expose port (if needed for future web interface)
EXPOSE 8080

# Run the application
CMD ["python", "main.py"]