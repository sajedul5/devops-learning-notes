#!/bin/bash

# Function to check if Docker is installed
check_docker_installed() {
  if command -v docker &> /dev/null
  then
    echo "Docker is already installed"
    return 0
  else
    return 1
  fi
}

# Function to install Docker
install_docker() {
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y docker.io
}

# Function to add user to Docker group
add_user_to_docker_group() {
  echo "Adding user to Docker group..."
  sudo usermod -aG docker $USER
}

# Function to set permissions on Docker socket
set_docker_socket_permissions() {
  echo "Setting permissions on Docker socket..."
  sudo chmod 666 /var/run/docker.sock
}

# Function to show Docker version
show_docker_version() {
  echo "Docker version:"
  docker --version
}

# Main script logic
if check_docker_installed
then
  echo "Skipping Docker installation"
else
  install_docker
  add_user_to_docker_group
  set_docker_socket_permissions
  echo "Docker installation and configuration complete. You may need to log out and log back in for the group changes to take effect."
fi

# Show Docker version
show_docker_version



