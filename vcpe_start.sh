#!/bin/bash

USAGE="
Usage:
    
vcpe_start <vcpe_name> <vnf_tunnel_ip> <home_tunnel_ip> <vcpe_private_ip> <vcpe_public_ip> <dhcpd_conf_file>
    being:
        <vcpe_name>: the name of the network service instance in OSM 
        <vnf_tunnel_ip>: the ip address for the vnf side of the tunnel
        <home_tunnel_ip>: the ip address for the home side of the tunnel
        <vcpe_private_ip>: the private ip address for the vcpe
        <vcpe_public_ip>: the public ip address for the vcpe (10.2.2.0/24)
        <dhcpd_conf_file>: the dhcp file for the vcpe to give private addresses to the home network
"

if [[ $# -ne 6 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi
SC="vcpe-1"
SC1="vCPE"
SC2="emu-vim12"
sudo osm ns-create


sleep 15
VNF1="mn.dc1_$1-1-ubuntu-1"
VNF2="mn.dc1_$1-2-ubuntu-1"
#VNF3="mn.dc1_$1-3-ubuntu-1"

VNFTUNIP="$2"
HOMETUNIP="$3"
VCPEPRIVIP="$4"
VCPEPUBIP="$5"
DHCPDCONF="$6"

#ETH11=`sudo docker exec -it $VNF1 ifconfig | grep eth1 | awk '{print $1}'`
ETH11=`sudo docker exec -it $VNF1 ifconfig | grep eth1 | awk '{print $1}'`
ETH21=`sudo docker exec -it $VNF2 ifconfig | grep eth1 | awk '{print $1}'`
#IP11=`sudo docker exec -it $VNF1 hostname -I | awk '{printf "%s\n", $1}{print $2}' | grep 192.168.100`
IP21=`sudo docker exec -it $VNF2 hostname -I | awk '{printf "%s\n", $1}{print $2}' | grep 192.168.100`
prov=`sudo docker exec -it mn.dc1_vcpe-1-1-ubuntu-1 ifconfig -a | awk '/192\.168\./ && /inet/{print $2}'`
IP11="${prov:5:14}"


echo $IP11
echo $IP21

##################### VNFs Settings #####################
## 0. Iniciar el Servicio OpenVirtualSwitch en cada VNF:
echo "--"
echo "--OVS Starting..."
sudo docker exec -it $VNF1 /usr/share/openvswitch/scripts/ovs-ctl start
sudo docker exec -it $VNF2 /usr/share/openvswitch/scripts/ovs-ctl start
#sudo docker exec -it $VNF3 /usr/share/openvswitch/scripts/ovs-ctl start

echo "--"
echo "--Connecting vCPE service with AccessNet and ExtNet..."

sudo ovs-docker add-port AccessNet veth0 $VNF1
sudo ovs-docker add-port ExtNet veth0 $VNF2

echo "--"
echo "--Setting VNF..."
echo "--"
echo "--Bridge Creating..."

## 1. En VNF:vclass agregar un bridge y asociar interfaces.
#sudo docker exec -it $VNF1 ovs-vsctl add-br br0
#sudo docker exec -it $VNF1 ifconfig veth0 $VNFTUNIP/24
#sudo docker exec -it $VNF1 ovs-vsctl add-port br0 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=$HOMETUNIP
#sudo docker exec -it $VNF1 ovs-vsctl add-port br0 vxlan2 -- set interface vxlan2 type=vxlan options:remote_ip=$IP21


## 2. En VNF:vcpe agregar un bridge y asociar interfaces.
sudo docker exec -it $VNF1 ovs-vsctl add-br br1
sudo docker exec -it $VNF1 ifconfig veth0 $VNFTUNIP netmask 255.255.255.0
#sudo docker exec -it $VNF1 ovs-vsctl add-port br1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=$HOMETUNIP
#sudo docker exec -it $VNF1 ovs-vsctl add-port br1 vxlan2 -- set interface vxlan2 type=vxlan options:remote_ip=$IP21
#sudo docker exec -it $VNF1 ifconfig br1 mtu 1400


## 3. En VNF:vcpe agregar un bridge y asociar interfaces.
sudo docker exec -it $VNF2 ovs-vsctl add-br br2
sudo docker exec -it $VNF2 /sbin/ifconfig br2 $VCPEPRIVIP/24
#sudo docker exec -it $VNF2 ovs-vsctl add-port br2 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=$IP11
sudo docker exec -it $VNF2 ifconfig br2 mtu 1400


#Vcpe: asignar dirección IP a interfaz de salida.
sudo docker exec -it $VNF2 /sbin/ifconfig veth0 $VCPEPUBIP/24
sudo docker exec -it $VNF2 ip route del 0.0.0.0/0 via 172.17.0.1
sudo docker exec -it $VNF2 ip route add 0.0.0.0/0 via 10.2.3.254

sudo docker exec -it $VNF1 route delete default gw 172.17.0.1 eth1-0
sudo docker exec -it $VNF1 route add default gw $IP21 eth1-0
sudo docker exec -it $VNF2 ip route add 10.255.0.0/24 via $IP11
sudo docker exec -it $VNF1 ip route add 10.2.2.0/24 via 10.255.0.2

## 4. Iniciar Servidor DHCP 
echo "--"
echo "--DHCP Server Starting..."
if [ -f "$DHCPDCONF" ]; then
    echo "--Using $DHCPDCONF for DHCP"
    docker cp $DHCPDCONF $VNF2:/etc/dhcp/dhcpd.conf
else
    echo "--$DHCPCONF not found for DHCP, the container will use the default"
fi
sudo docker exec -it $VNF2 service isc-dhcp-server restart
sleep 30

## 5. En VNF:vcpe activar NAT para dar salida a Internet 
docker cp /usr/bin/vnx_config_nat  $VNF2:/usr/bin
sudo docker exec -it $VNF2 /usr/bin/vnx_config_nat br2 veth0
docker cp /usr/bin/vnx_config_nat  $VNF1:/usr/bin
sudo docker exec -it $VNF1 /usr/bin/vnx_config_nat veth0 eth1-0
docker cp /home/upm/Desktop/NFV-LAB-2019/configuration.yaml  $VNF1:/config


sudo docker exec -it $VNF2 iptables -t nat -A PREROUTING -p tcp -d 10.2.3.1 --dport 8123 -j DNAT --to-destination $IP11:8123
sudo docker exec -it $VNF2 iptables -t nat -A POSTROUTING ! -s 127.0.0.1 -j MASQUERADE
sudo docker exec -it $VNF2 iptables-save > /etc/iptables.rules
sudo docker exec -it $VNF2 iptables-restore < /etc/iptables.rules
#sudo docker exec -it $VNF2 iptables -A FORWARD -p tcp -d $IP11 --dport 8123 -j ACCEPT
#sudo docker exec -it $VNF2 iptables -A FORWARD -p tcp -s $IP11 --sport 8123 -j ACCEPT
#sudo docker exec -it $VNF2 iptables -A PREROUTING -t nat -p tcp -d 10.2.3.1 --dport 8123 -j DNAT --to-destination $IP11:8123
#sudo docker exec -it $VNF2 iptables -A POSTROUTING -t nat -p tcp -d $IP11 --dport 8123 -j SNAT --to-source 10.2.3.254
#sudo docker exec -it $VNF2 iptables-save


sleep 5
sudo vnx -f nfv3_home_lxc_ubuntu64.xml -t
sleep 15
sudo vnx -f nfv3_server_lxc_ubuntu64.xml -t

