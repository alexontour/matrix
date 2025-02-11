#!/bin/bash

# Function to read the Docker Compose version
get_docker_compose_version() {
    read -p "Enter the Docker Compose version you want to install (e.g., 2.26.0): " docker_compose_version
    if [[ -z "$docker_compose_version" ]]; then
        echo "No version entered. Using the latest version."
        docker_compose_version="latest"
    fi
    echo "$docker_compose_version"
}

# Update the package index
echo "Updating package index..."
sudo apt-get update -y

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable Docker repository
echo "Setting up the Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Verify Docker installation
echo "Verifying Docker installation..."
docker --version

# Enable and start Docker service
echo "Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Get Docker Compose version
docker_compose_version=$(get_docker_compose_version)

# Install Docker Compose
if [[ "$docker_compose_version" == "latest" ]]; then
    compose_url="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
else
    compose_url="https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)"
fi

echo "Installing Docker Compose version: $docker_compose_version..."
sudo curl -L "$compose_url" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
echo "Verifying Docker Compose installation..."
docker-compose --version

# Install Portainer
echo "Installing Portainer..."
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Output success message
echo "Installation complete!"
echo "Docker, Docker Compose, and Portainer have been successfully installed."
echo "Access Portainer at: https://<your-server-ip>:9443"
