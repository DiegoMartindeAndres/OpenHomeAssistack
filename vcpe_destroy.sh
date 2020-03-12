#!/bin/bash



VNF1="mn.dc1_vcpe-1-1-ubuntu-1"
VNF2="mn.dc1_vcpe-1-2-ubuntu-1"

sudo ovs-docker del-port AccessNet veth0 $VNF1
sudo ovs-docker del-port ExtNet veth0 $VNF2

osm ns-delete vcpe-1
sleep 3
sudo vnx -f nfv3_home_lxc_ubuntu64.xml --destroy
sudo vnx -f nfv3_server_lxc_ubuntu64.xml --destroy
