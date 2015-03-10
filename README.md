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
yum install wget unzip -y
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
On your OSSEC server enable ability to send alerts via syslog
```
/var/ossec/bin/ossec-control enable client-syslog
```
Then add in /var/ossec/etc/ossec.conf this lines to send ossec alerts via sysslog in logstash
```
<ossec_config>

...

   <syslog_output>
   <server>192.168.1.8</server>
   <port>9000</port>
   <format>default</format>
   </syslog_output>
...
</ossec_config>