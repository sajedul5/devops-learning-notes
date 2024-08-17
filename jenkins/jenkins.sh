#!/bin/bash

# Update package lists
sudo apt update -y

# Uncomment the following line if you want to upgrade all packages
# sudo apt upgrade -y

# Check if Temurin 17 JDK is installed
if ! java -version 2>&1 | grep -q '17.*Temurin'; then
    echo "Temurin 17 JDK not found. Installing..."
    
    # Add the Adoptium GPG key and repository for Temurin 17 JDK
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
    
    # Update package lists again and install Temurin 17 JDK
    sudo apt update -y
    sudo apt install temurin-17-jdk -y

    # Verify Java installation
    /usr/bin/java --version
else
    echo "Temurin 17 JDK is already installed. Skipping installation."
fi

# Check if Jenkins is installed
if ! dpkg -l | grep -q jenkins; then
    echo "Jenkins not found. Installing..."

    # Add Jenkins GPG key and repository
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    # Update package lists and install Jenkins
    sudo apt-get update -y
    sudo apt-get install jenkins -y

    # Start Jenkins and check its status
    sudo systemctl start jenkins
    sudo systemctl status jenkins
else
    echo "Jenkins is already installed. Skipping installation."
fi






