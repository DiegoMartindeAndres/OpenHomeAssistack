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

VNFTUNIP="$2"
HOMETUNIP="$3"
VCPEPRIVIP="$4"
VCPEPUBIP="$5"
DHCPDCONF="$6"

ETH11=`sudo docker exec -it $VNF1 ifconfig | grep eth1 | awk '{print $1}'`
ETH21=`sudo docker exec -it $VNF2 ifconfig | grep eth1 | awk '{print $1}'`
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


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 1. En VNF:home agregar un bridge y asociar interfaces.
sudo docker exec -it $VNF1 ovs-vsctl add-br br1
sudo docker exec -it $VNF1 ifconfig veth0 $VNFTUNIP netmask 255.255.255.0


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 2. En VNF:vcpe agregar un bridge y asociar interfaces.
sudo docker exec -it $VNF2 ovs-vsctl add-br br2
sudo docker exec -it $VNF2 /sbin/ifconfig br2 $VCPEPRIVIP/24
sudo docker exec -it $VNF2 ifconfig br2 mtu 1400


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 3.VCPE: asignar rutas a la interfaz de salida y a la interfaz de entrada.
sudo docker exec -it $VNF2 /sbin/ifconfig veth0 $VCPEPUBIP/24
sudo docker exec -it $VNF2 ip route del 0.0.0.0/0 via 172.17.0.1
sudo docker exec -it $VNF2 ip route add 0.0.0.0/0 via 10.2.3.254

sudo docker exec -it $VNF1 route delete default gw 172.17.0.1 eth1-0
sudo docker exec -it $VNF1 route add default gw $IP21 eth1-0
sudo docker exec -it $VNF2 ip route add 10.255.0.0/24 via $IP11
sudo docker exec -it $VNF1 ip route add 10.2.2.0/24 via 10.255.0.2


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


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


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 5. En VNF:vcpe y home configuramos NAT para dar salida a Internet y redirigir conexiones entrantes al router
######en el puerto 8213 al docker de Home Assistant. 
docker cp /usr/bin/vnx_config_nat  $VNF2:/usr/bin
sudo docker exec -it $VNF2 /usr/bin/vnx_config_nat br2 veth0
docker cp /usr/bin/vnx_config_nat  $VNF1:/usr/bin
sudo docker exec -it $VNF1 /usr/bin/vnx_config_nat veth0 eth1-0
docker cp /home/upm/Desktop/NFV-LAB-2019/configuration.yaml  $VNF1:/config

sudo docker exec -it $VNF2 iptables -t nat -A PREROUTING -p tcp -d 10.2.3.1 --dport 8123 -j DNAT --to-destination $IP11:8123
sudo docker exec -it $VNF2 iptables -t nat -A POSTROUTING ! -s 127.0.0.1 -j MASQUERADE
sudo docker exec -it $VNF2 iptables-save > /etc/iptables.rules
sudo docker exec -it $VNF2 iptables-restore < /etc/iptables.rules


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 6. Arrancar los escenarios virtuales.
sleep 3
sudo vnx -f nfv3_home_lxc_ubuntu64.xml -t
sleep 8
sudo vnx -f nfv3_server_lxc_ubuntu64.xml -t

#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 7. Asignamos IP externa a R1 e instalamos mosquitto en los equipos de la red residencial.
sleep 3
sudo lxc-attach -n r1 -- dhclient
sudo lxc-attach -n h11 -- apt-get update 
sudo lxc-attach -n h11 -- apt-get -y install mosquitto mosquitto-clients python3-pip
sudo lxc-attach -n h11 -- pip3 install paho-mqtt python-etcd
sudo lxc-attach -n h11 -- python3 sensor.py -b 10.2.2.10
sudo lxc-attach -n h12 -- apt-get update 
sudo lxc-attach -n h12 -- apt-get -y install mosquitto mosquitto-clients
sudo lxc-attach -n br1 -- apt-get update 
sudo lxc-attach -n br1 -- apt-get -y install mosquitto mosquitto-clients
sudo lxc-attach -n aux -- apt-get update 
sudo lxc-attach -n aux -- apt-get -y install mosquitto mosquitto-clients


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 8. Lanzamos script de Connectivity Testing.
sleep 60
sudo lxc-attach -n br1 -- sudo bash /root/script.sh

