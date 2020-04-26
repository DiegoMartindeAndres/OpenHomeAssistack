#!/bin/bash


sudo ovs-vsctl del-br br1
sudo ovs-vsctl del-br AccessNet
sudo ovs-vsctl del-br ExtNet

VNF1="mn.dc1_vcpe-1-1-ubuntu-1"

sudo ovs-docker del-port AccessNet veth0 $VNF1
sudo ovs-docker del-port ExtNet veth1 $VNF1

osm ns-delete vcpe-1
sleep 3
sudo vnx -f nfv3_home_lxc_ubuntu64.xml --destroy
sudo vnx -f nfv3_server_lxc_ubuntu64.xml --destroy
