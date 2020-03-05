IP21=`sudo docker exec -it mn.dc1_vcpe-1-2-ubuntu-1 ifconfig -a | awk '/192\.168\./ && /inet/{print $2}'`
echo $IP21
IP21="${IP21:5:14}"
echo $IP21
