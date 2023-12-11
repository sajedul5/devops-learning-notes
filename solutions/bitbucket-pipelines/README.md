To set up a Bitbucket Pipeline for deploying a Dockerized application to an EC2 instance via SSH, you can follow these general steps. This assumes you have a Dockerized application and an EC2 instance available for deployment.

Prerequisites:
Bitbucket Repository Setup:

Your Bitbucket repository contains the Dockerized application and a Dockerfile.
EC2 Instance:

Have an EC2 instance running with Docker installed.
Ensure the instance is configured to allow SSH access.
Steps:
1. Generate SSH Key Pair:
Generate an SSH key pair as mentioned in the previous response.

2. Add SSH Key to Bitbucket:
Add the public key to your Bitbucket repository as mentioned in the previous response.

3. Configure bitbucket-pipelines.yml:
Create or modify the bitbucket-pipelines.yml file in your repository with the following content:
Replace the placeholders (your-ec2-ip-or-domain, /path/to/destination, your-docker-files) with your actual values.

4. Set Environment Variable in Bitbucket:
In your Bitbucket repository, go to Settings > Repository settings > Pipeline > Repository settings and add an environment variable:

Variable: SSH_PRIVATE_KEY
Value: Paste the content of your private SSH key (~/.ssh/id_rsa).
5. Docker Compose File:
Ensure you have a docker-compose.yml file in your project that defines how your Dockerized application should run.

6. Commit and Push:
Commit and push the changes to your Bitbucket repository to trigger the pipeline.

Important Notes:
The example assumes you are using Docker Compose to manage your Docker containers. Modify the Docker-related commands based on your specific setup.
Make sure Docker is installed on your EC2 instance and the Docker daemon is running.
Ensure that your Docker Compose file and deployment script match your application's requirements.
Be cautious with security, especially when dealing with private keys. Use Bitbucket Pipeline secrets for sensitive information.