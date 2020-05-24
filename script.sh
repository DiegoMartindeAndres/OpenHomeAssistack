SERVICE="hass"
while true
do
if ping -q -c 1 -W 1 10.255.0.1 >/dev/null; then
  echo "IPv4 is up"
  sshpass -p 'root' scp root@10.255.0.1:/config/configuration.yaml .
  sleep 15
else
  echo "IPv4 is down"
  if pgrep -x "$SERVICE" >/dev/null
  then
    echo "$SERVICE is running"
    sleep 15
  else
    echo "$SERVICE stopped"
    route add default gw 192.168.122.1 eth9
    /usr/bin/vnx_config_nat eth1 eth9
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get -y install python3 python3-dev python3-venv python3-pip libffi-dev libssl-dev
    sudo useradd -rm homeassistant -G dialout,gpio,i2c
    cd /srv
    sudo mkdir homeassistant
    sudo chown homeassistant:homeassistant homeassistant
    sudo -u homeassistant -H -s
    cd /srv/homeassistant
    python3 -m venv .
    source bin/activate
    sleep 30
    python3 -m pip install wheel
    pip3 install homeassistant
    hass &
    sleep 55
    sed -i 's/broker: 10.255.0.2/broker: 10.2.2.4/' configuration.yaml
    # uncomment to start hass if stopped
    # systemctl start nginx
    # mail
    sleep 5  
  fi
fi
done


