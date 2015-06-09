#!/bin/bash

sudo -s
WLAN=192.168.54.96

#super user access


#flushing existing rules
iptables -F


#setting default policy as accept packets
iptables --policy INPUT ACCEPT
iptables --policy OUTPUT ACCEPT
iptables --policy FORWARD ACCEPT

#blocking a port which is used by an application containing some sensitive information
iptables -A INPUT -p tcp --dport 11001 -j DROP
iptables -A OUTPUT -p tcp --dport 11001 -j DROP

#allowing ssh to specific machines for managing the gateway(this machine)
iptables -A INPUT -d -p tcp --dport ssh -s 192.168.48.83 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d -p tcp --sport 22 -d 192.168.48.83 -m state --state ESTABLISHED -j ACCEPT

#adding a rule for dropping other ssh connection requests
iptables -A INPUT -p tcp --dport 22 -j DROP
iptables -A OUTPUT -p tcp --dport 22 -j DROP

#blocking ftp ports
iptables -A INPUT -p tcp --dport 21 -j DROP
iptables -A OUTPUT -p tcp --dport 21 -j DROP

#blocking telnet port
iptables -A INPUT -p tcp --dport 23 -j DROP
iptables -A OUTPUT -p tcp --dport 23 -j DROP

#blocking dns port
iptables -A INPUT -p tcp --dport 53 -j DROP
iptables -A OUTPUT -p tcp --dport 53 -j DROP

########################################################################


#session limit


# Max connection in seconds = 100


# Max connections per IP = 10
BLOCKCOUNT=10
iptables -A INPUT -p tcp --dport 80 -i wlan0 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 80 -i wlan0 -m state --state NEW -m recent --update --seconds 100 --hitcount 10 -j DROP


##########################################################################

#NAT prerouting and postrouting
iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit -above 5 -j REJECT --reject-with tcp-reset

#informing the kernel that we ant to enable ip forwarding
echo "1" > /proc/sys/net/ipv4/ip_forward
   
#Load various modules. Usually they are already loaded 
#(especially for newer kernels), in that case 
#the following commands are not needed.
    
#Load iptables module:
modprobe ip_tables
   
#activate connection tracking
#(connection's status are taken into account)
modprobe ip_conntrack

#Special features for IRC:
modprobe ip_conntrack_irc

#Special features for FTP:
modprobe ip_conntrack_ftp

#inform kernel to enable ip forwarding
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

#restarting iptable to commit changes

#saving the changes made to the iptable becuase if we don't change these settings they will be lost on the next reboot
iptables-save
