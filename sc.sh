VNF3="mn.dc1_vcpe-1-3-ubuntu-1"

IP31=`sudo docker exec -it $VNF3 hostname -I | awk '{printf "%s\n", $1}{print $2}' | grep 192.168.100`
prov=`sudo docker exec -it mn.dc1_vcpe-1-2-ubuntu-1 ifconfig -a | awk '/192\.168\./ && /inet/{print $2}'`
IP21="${prov:5:14}"
sudo docker exec -it $VNF3 /usr/bin/vnx_config_nat br2 veth0
sudo docker exec -it $VNF3 iptables -A FORWARD -p tcp -d $IP21 --dport 8123 -j ACCEPT
sudo docker exec -it $VNF3 iptables -A FORWARD -p tcp -s $IP21 --sport 8123 -j ACCEPT
sudo docker exec -it $VNF3 iptables -A PREROUTING -t nat -p tcp -d 10.2.3.1 --dport 8123 -j DNAT --to-destination $IP21:8123
sudo docker exec -it $VNF3 iptables -A POSTROUTING -t nat -p tcp -d $IP21 --dport 8123 -j SNAT --to-source 10.2.3.254
sudo docker exec -it $VNF3 iptables-save
