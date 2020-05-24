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
"

if [[ $# -ne 5 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi


sudo osm ns-create


sleep 15
VNF1="mn.dc1_$1-1-ubuntu-1"

VNFTUNIP="$2"
HOMETUNIP="$3"
VCPEPRIVIP="$4"
VCPEPUBIP="$5"


ETH11=`sudo docker exec -it $VNF1 ifconfig | grep eth1 | awk '{print $1}'`
prov=`sudo docker exec -it mn.dc1_vcpe-1-1-ubuntu-1 ifconfig -a | awk '/192\.168\./ && /inet/{print $2}'`
IP11="${prov:5:14}"


echo $IP11

##################### VNFs Settings #####################
## 0. Iniciar el Servicio OpenVirtualSwitch en cada VNF:
echo "--"
echo "--OVS Starting..."
sudo docker exec -it $VNF1 /usr/share/openvswitch/scripts/ovs-ctl start


echo "--"
echo "--Connecting vCPE service with AccessNet and ExtNet..."


sudo ovs-docker add-port AccessNet veth0 $VNF1
sleep 5
sudo ovs-docker add-port ExtNet veth1 $VNF1
sleep 5


echo "--"
echo "--Setting VNF..."
echo "--"
echo "--Bridge Creating..."


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## En VNF:home agregar un bridge y asociar interfaces.
sudo docker exec -it $VNF1 ovs-vsctl add-br br1

sudo docker exec -it $VNF1 ifconfig veth0 $VNFTUNIP netmask 255.255.255.0
sudo docker exec -it $VNF1 ifconfig veth1 $VCPEPUBIP netmask 255.255.255.0

echo ""
echo ""
echo "----------------------------DONE----------------------------------"
echo ""
echo ""

#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## VCPE: asignar rutas a la interfaz de salida y a la interfaz de entrada.

sudo docker exec -it $VNF1 ip route del 0.0.0.0/0 via 172.17.0.1
sudo docker exec -it $VNF1 ip route add 0.0.0.0/0 via 10.2.3.254
echo ""
echo ""
echo "----------------------------DONE2----------------------------------"
echo ""
echo ""

sudo docker exec -it $VNF1 ip route add 10.2.2.0/24 via 10.255.0.2

echo ""
echo ""
echo "----------------------------DONE3----------------------------------"
echo ""
echo ""
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## En VNF:vcpe y home configuramos NAT para dar salida a Internet y redirigir conexiones entrantes al router
######en el puerto 8213 al docker de Home Assistant. 
docker cp /usr/bin/vnx_config_nat  $VNF1:/usr/bin
sudo docker exec -it $VNF1 /usr/bin/vnx_config_nat br1 veth1
echo ""
echo ""
echo "----------------------------DONE4----------------------------------"
echo ""
echo ""

docker cp /usr/bin/vnx_config_nat  $VNF1:/usr/bin
sudo docker exec -it $VNF1 /usr/bin/vnx_config_nat veth0 eth1-0

echo ""
echo ""
echo "----------------------------DONE5----------------------------------"
echo ""
echo ""

docker cp /home/upm/Desktop/NFV-LAB-2019/configuration.yaml  $VNF1:/config

sudo docker exec -it $VNF1 iptables -t nat -A PREROUTING -p tcp -d 10.2.3.1 --dport 8123 -j DNAT --to-destination $IP11:8123
sudo docker exec -it $VNF1 iptables -t nat -A POSTROUTING ! -s 127.0.0.1 -j MASQUERADE
sudo docker exec -it $VNF1 iptables-save > /etc/iptables.rules
sudo docker exec -it $VNF1 iptables-restore < /etc/iptables.rules


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 6. Arrancar los escenarios virtuales.
sleep 3
sudo vnx -f nfv3_home_lxc_ubuntu64.xml -t
sleep 8
sudo vnx -f nfv3_server_lxc_ubuntu64.xml -t


#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------------#


## 7. Asignamos IP externa a R1 e instalamos mosquitto en los equipos de la red residencial.
sleep 3
sudo lxc-attach -n r1 -- dhclient
sudo docker exec -it $VNF1 apk add openssh
sudo docker exec -it $VNF1 apk add sshpass
sudo docker exec -it $VNF1 apk add openrc
sudo docker exec -it $VNF1 rc-update add sshd
sudo docker exec -it $VNF1 rc-status
sudo docker exec -it $VNF1 touch /run/openrc/softlevel
sudo docker exec -it $VNF1 /etc/init.d/sshd start
sudo docker exec -it $VNF1 sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' sshd_config
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

