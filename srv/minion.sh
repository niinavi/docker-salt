#!bin/bash
# sudo bash minion.sh

setxkbmap fi
echo "Installing salt-minion and Git"
sudo apt-get update
sudo apt-get -y install git salt-minion firefox

echo "Minion configuration."
echo "Please enter master IP"
read MasterIp
echo "Please enter an unique id for your minion:"
read MinionId
echo "Retrieving and applying settings.."
echo -e "master: $MasterIp\nid: $MinionId" | sudo tee /etc/salt/minion

systemctl restart salt-minion
