#!/bin/bash
#paranoidtruth

#PATH TO CURRENT GAMECASH:  YOU MUST ALSO CHANGE TAR & MV COMMANDS
FILE_NAME="https://github.com/gamecashproject/gcash"

echo "=================================================================="
echo "GAMECASH Coin MN Install"
echo "=================================================================="
echo "Installing, this will take appx 2 min to run..."
read -p 'Enter your masternode genkey you created in windows, then [ENTER]: ' GENKEY

echo -n "Installing pwgen..."
sudo apt-get install pwgen 

echo -n "Installing dns utils..."
sudo apt-get install dnsutils

PASSWORD=$(pwgen -s 64 1)
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)

echo -n "Installing with GENKEY: $GENKEY, RPC PASS: $PASSWORD, VPS IP: $WANIP..."

#begin optional swap section
echo "Setting up disk swap..."
free -h 
sudo fallocate -l 4G /swapfile 
ls -lh /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab sudo bash -c "
echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
free -h
echo "SWAP setup complete..."
#end optional swap section

echo "Installing packages and updates..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install build-essential libssl-dev libdb++-dev libboost-all-dev libqrencode-dev -y
sudo apt-get install libssl1.0-dev -y
sudo apt-get install libqt4-dev libminiupnpc-dev -y
echo "Downloading gamecash wallet..."
git clone $FILE_NAME
cd gamecash
cd src
mkdir obj
cd obj
mkdir crypto
cd ..
make -f makefile.unix
sudo cp gamecashd /usr/local/bin

echo "INITIAL START: IGNORE ANY CONFIG ERROR MSGs..." 
gamecashd

echo "Loading wallet, be patient, wait..." 
sleep 30
gamecashd getmininginfo
gamecashd stop

echo "creating config..." 

cat <<EOF > ~/.Gamecash/gamecash.conf
rpcuser=gamecashadminrpc
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcport=58754
listen=1
server=1
daemon=1
maxconnections=64
listenonion=0
port=58753
masternode=1
masternodeaddr=$WANIP:58754
masternodeprivkey=$GENKEY
addnode=35.163.149.91
EOF

echo "setting basic security..."
sudo apt-get install fail2ban -y
sudo apt-get install ufw -y
sudo apt-get update -y

#add a firewall & fail2ban
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow 48754/tcp
sudo ufw logging on
sudo ufw status
sudo ufw enable -y

#fail2ban:
sudo systemctl enable fail2ban -y
sudo systemctl start fail2ban -y
echo "basic security completed..."

echo "restarting wallet, be patient, wait..."
gamecashd
sleep 30

echo "gamecashd getmininginfo:"
gamecashd getmininginfo

echo "Note: installed with IP: $WANIP and genkey: $GENKEY.  If either are incorrect, you will need to edit the .Gamecash/gamecash.conf file"
echo "Done!  It may take time to sync, you can start your final setup checks in the guide once the block count is sync'd"
