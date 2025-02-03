#!/bin/bash

echo "updating apt..."
sudo apt update
echo "apt updated successfully..."

echo "installing git..."
sudo apt install git -y
echo "git installed successfully..."
git --version

echo "cloning git repo"
git clone https://github.com/SagarSingh2003/HTTP_over_TCP.git
echo "git repo clone successfully..."

cd HTTP_over_TCP

echo "installing nodejs and npm"
sudo apt install -y nodejs npm
echo "nodejs installed successfully"

echo "installing node modules"
npm install 

echo "killing all the processes running on 3000 and freeing up the port"
kill -9 $(lsof -t -i :3000)

echo "starting the server"
node node_net.js