#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing .NET 9 SDK ==="
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-9.0

echo "=== Installing Azure CLI ==="
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "=== Post-build setup complete! ==="
