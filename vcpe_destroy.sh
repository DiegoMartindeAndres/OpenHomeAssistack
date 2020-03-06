#!/bin/bash

USAGE="
Usage:
    
vcpe_destroy <vcpe_name> 

    being:
        <vcpe_name>: the name of the network service instance in OSM 
"

if [[ $# -ne 1 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi

VNF1="mn.dc1_$1-1-ubuntu-1"
VNF2="mn.dc1_$1-3-ubuntu-1"

sudo ovs-docker del-port AccessNet veth0 $VNF1
sudo ovs-docker del-port ExtNet veth0 $VNF2

osm ns-delete $1
sleep 3
sudo vnx -f nfv3_home_lxc_ubuntu64.xml --destroy
sudo vnx -f nfv3_server_lxc_ubuntu64.xml --destroy
