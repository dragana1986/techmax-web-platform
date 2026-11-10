#!/bin/bash

# Values filled in by Terraform templatefile()
export S3_URI="${s3_uri}"
export APPLICATION_CODE_FILE_NAME="${app_name}"

# Update the packages on the EC2 instance
sudo yum update -y

# Install the Apache HTTP Server and unzip
sudo yum install -y httpd unzip

# Change to the Apache web root directory
cd /var/www/html

# Remove any existing files
sudo rm -rf *

# Download the application package from the S3 bucket
sudo aws s3 cp "$S3_URI" "$APPLICATION_CODE_FILE_NAME.zip"

# Unzip the downloaded file
sudo unzip -q "$APPLICATION_CODE_FILE_NAME.zip"

# Copy the contents to the html directory
sudo cp -R "$APPLICATION_CODE_FILE_NAME/." .

# Clean up zip file and extracted folder
sudo rm -rf "$APPLICATION_CODE_FILE_NAME" "$APPLICATION_CODE_FILE_NAME.zip"

# Enable Apache to run on boot
sudo systemctl enable httpd

# Start Apache service
sudo systemctl start httpd
