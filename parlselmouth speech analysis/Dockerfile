# 3.10 or 3.11 is recommended for better TensorFlow compatibility
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Install system libraries required for audio analysis (libsndfile)
# We need ffmpeg to convert WebM to WAV, fonts to display jp
RUN apt-get update && apt-get install -y \
    libsndfile1 \
    ffmpeg \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container at /app
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
# --no-cache-dir to keep the image small
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the working directory contents into the container at /app
COPY . .

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Run the application using Gunicorn (Production Server)
# 'visualise:app' -> look inside visualise.py for the object named 'app'
# --timeout 120: Gives the AI model time to process without timing out
# --bind 0.0.0.0:$PORT: This is REQUIRED for Render
CMD gunicorn --bind 0.0.0.0:$PORT --timeout 120 visualise:app