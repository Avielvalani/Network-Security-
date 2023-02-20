#!/bin/bash

# Network security script

# Set variables
ip="192.168.0.1" # Change this to your router's IP address
subnet="192.168.0.0/24" # Change this to your subnet's IP range
interface="eth0" # Change this to your network interface name
dns1="8.8.8.8" # Change this to your preferred DNS server
dns2="8.8.4.4" # Change this to your backup DNS server

# Disable unnecessary services
systemctl stop avahi-daemon
systemctl disable avahi-daemon
systemctl stop cups
systemctl disable cups

# Install and configure firewall
apt-get update
apt-get install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw enable

# Configure network interface
cat << EOF > /etc/network/interfaces
auto $interface
iface $interface inet static
  address $ip
  netmask 255.255.255.0
  network $subnet
  gateway $ip
  dns-nameservers $dns1 $dns2
EOF

# Disable root login over SSH
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Enable password authentication over SSH
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' 
/etc/ssh/sshd_config

# Set strong password policy
cat << EOF > /etc/security/pwquality.conf
minlen = 12
minclass = 4
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
EOF

# Install and configure fail2ban
apt-get install fail2ban -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i 's/bantime = 600/bantime = 3600/' /etc/fail2ban/jail.local
systemctl restart fail2ban

# Configure log rotation
cat << EOF > /etc/logrotate.d/custom
/var/log/syslog
{
    rotate 7
    daily
    missingok
    notifempty
    delaycompress
    compress
    postrotate
        /usr/bin/systemctl restart rsyslog.service >/dev/null 2>&1 || true
    endscript
}
EOF

# Set secure file permissions
find / -perm /6000 -type f -exec chmod a-s {} \;
chmod 640 /etc/shadow
chmod 640 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group

# Disable root login through console
echo "tty1" >> /etc/securetty

# Install and configure rkhunter
apt-get install rkhunter -y
rkhunter --update
rkhunter --propupd
rkhunter --check

# Install and configure logwatch
apt-get install logwatch -y
cat << EOF > /etc/cron.daily/00logwatch
#!/bin/sh
/usr/sbin/logwatch --output mail --mailto your-email@example.com --detail 
high
EOF
chmod +x /etc/cron.daily/00logwatch

# Set system-wide umask
echo "umask 027" >> /etc/profile

# Set up automatic security updates
apt-get install unattended

