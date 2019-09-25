#!/bin/bash

# nocr.sh - script for creating multiple NOIA nodes to VPS'es - ver. 190905-1

clear

#Edit here the VPS IP addresses:

hosts="95.216.215.192"

echo
echo "Let's set up a NOIA node!"
echo
echo -n 'Give your username: '
read userName
echo -n 'Give your root/sudo password: '
read sudoPsw
echo -n 'Give your password for ssh: '
read userPsw

echo 2>/dev/null
echo '**** Installing sshpass for the remote connection...' 2>/dev/null
echo $sudoPsw |sudo -S apt install sshpass

script='echo 2>/dev/null
echo "**** Installing NOIA node to "`hostname` 2>/dev/null
echo 2>/dev/null
echo "**** Installing obligatory modules..." 2>/dev/null
sleep 2 2>/dev/null
cd ~
echo $sudoPsw |sudo -S apt -y update
sudo apt -y install curl git build-essential python-dev

echo "**** Ensuring we have correct version of node.js installed..." 2>/dev/null
sleep 2 2>/dev/null
sudo apt -y remove nodejs
curl -sL https://deb.nodesource.com/setup_10.x | bash -
sudo apt -y install nodejs

echo "**** Fetching node-cli package..." 2>/dev/null
sleep 2 2>/dev/null
git clone https://github.com/noia-network/noia-node-cli.git

echo 2>/dev/null
echo "**** Installing npm..." 2>/dev/null
sleep 2 2>/dev/null
cd ~/noia-node-cli
sudo apt  -y install npm
npm install

echo "**** Fixing npm vulnerabilities, doing npm build..." 2>/dev/null
sleep 2 2>/dev/null
npm audit fix
npm run build

echo "**** Updating npm to the newest version..." 2>/dev/null
sleep 2 2>/dev/null
sudo npm install -g npm

echo 2>/dev/null
echo "**** Creating NOIA service and preparing the node, wait..." 2>/dev/null
sleep 2 2>/dev/null
cd ~
NUser=`users |cut -f 1 -d " "`
NHome=`pwd`
echo "[Unit]
Description=noia
[Service]
User=$NUser
WorkingDirectory=$NHome/noia-node-cli
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=7
[Install]
WantedBy=default.target" > noia.service
sudo cp noia.service /etc/systemd/system/noia.service
sudo systemctl enable noia.service
sudo systemctl start noia.service
sleep 10
echo "Stopping the node and editing the node settings..." 2>/dev/null
sudo systemctl stop noia.service
echo 2>/dev/null

echo -n "Give your airdrop address: (Give null if none)"
read usrAirdropAddress
echo -n "Enable NAT port mapping? (true/false): "
read usrNatPmp
echo -n "Define shared storage size in megabytes: "
read usrSize
usrSize=$(( 1024 * 1024 * $usrSize))
echo 2>/dev/null

echo "Setting airdrop address to $usrAirdropAddress" 2>/dev/null
sed -i "s/airdropAddress=.*/airdropAddress=$usrAirdropAddress/g" ~/.noia-node/node.settings
echo "Setting natPmp to $usrNatPmp" 2>/dev/null
sed -i "s/natPmp=.*/natPmp=$usrNatPmp/g" ~/.noia-node/node.settings
echo "Setting storage size to $usrSize" 2>/dev/null
sed -i "s/size=.*/size=$usrSize/g" ~/.noia-node/node.settings
echo 2>/dev/null
echo "Restarting the node service" 2>/dev/null
sudo systemctl start noia.service

echo 2>/dev/null
echo "**** Done! Now log in to your new node and check the node status with command:" 2>/dev/null
echo "**** sudo journalctl -fu noia.service" 2>/dev/null
echo 2>/dev/null

exit'

for host in ${hosts} ; do
  sshpass -p ${userPsw} ssh -t -o StrictHostKeyChecking=no ${userName}@${host} "${script}"
done
