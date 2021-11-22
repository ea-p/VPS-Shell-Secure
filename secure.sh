#!/bin/bash
# init

##Variables
#User prompt
echo "Enter your username:"
read USER
echo "Enter your email: (optional)"
read EMAIL
echo "Enter your port"
read PORT

#Confirm prompt
echo -en "Username: $USER \nEmail (optional): $EMAIL \nPort: $PORT\nContinue (y/n)?"
read answer

if ![ "$answer" != "${answer#[Yy]}" ] ;then
    exit
fi



#pause
function pause(){
   read -p "$*"
}

##Update and Upgrade first
apt-get update -y
apt-get upgrade -y

##Create user
adduser --disabled-password --gecos "" $USER
adduser $USER sudo

#Create SSH keys
mkdir /home/$USER/.ssh
ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f /home/$USER/.ssh/id_rsa -q -N ""
chmod -R 700 /home/$USER/.ssh
touch /home/$USER/.ssh/authorized_keys
cat /home/$USER/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER/.ssh

#Promtp to read $USER SSH key
echo "Please copy the following SSH private key:"
cat /home/$USER/.ssh/id_rsa
pause 'Press [Enter] to continue after having copied the key. If you fail to cpy the key now it will be forever lost.'

#Delete private key
rm /home/$USER/.ssh/id_rsa

##Securing the server
#Create custom sshd_config
cat > /etc/ssh/sshd_config.d/custom_secure.conf << EOF
# Custom sshd_config
#
PORT 22
LoginGraceTime 30s
MaxAuthTries 3
PubkeyAuthentication yes
Authorizedkeysfile	.ssh/authorized_keys
PermitRootLogin no
StrictModes yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
PrintLastLog yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

#configure ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow $PORT/tcp
ufw allow 80/tcp
ufw allow ssh
ufw disable
ufw enable


#Restart sshd 
systemctl restart sshd

