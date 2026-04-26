# Use the official Playwright image as base to include all browser dependencies
FROM mcr.microsoft.com/playwright:v1.44.0-jammy

# Set labels
LABEL maintainer="Hermes Agent Setup Guide"
LABEL description="Docker image for Hermes Agent with Ollama integration"

# Install additional system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes Agent via the official installation script
# We run it as root, and it will install to /root/.hermes
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Add Hermes binary directory to PATH
ENV PATH="/root/.hermes/bin:${PATH}"

# Set working directory for user projects/workspace
WORKDIR /app

# Set environment variables for Ollama connection
# host.docker.internal is used to reach the host machine from the container
ENV HERMES_BASE_URL="http://host.docker.internal:11434/v1"

# Default command to run when starting the container
# This allows the container to be used as a CLI tool
ENTRYPOINT ["hermes"]
CMD ["chat"]
