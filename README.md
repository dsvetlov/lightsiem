# LightSIEM
Lightweight and sexy Security Information and Event Managment system for OSSEC, Snort and other IDS/IPS
# Installation
LightSIEM now distributing as ansible playbook for RHEL/CentOS/Oracle Linix 7.x.
Install EPEL repository
```
yum install http://fedora-mirror01.rbc.ru/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm -y
```
Install Ansible and additional packages
```
yum install ansible -y
yum install wget unzip
```
Download latest playbook code and unpack it
```
wget https://github.com/dsvetlov/lightsiem/archive/master.zip
unzip master.zip
```
Run playbook
```
ansible-playbook lightsiem-master/lightsiem-install.yml
```
