FROM homeassistant/home-assistant
# install required packages
RUN apk update \
    && apk add  git \
    net-tools \
#    aptitude \
    build-base \
    py-setuptools \
    python-dev \
    py-pip \
#    python-software-properties \
    ansible \
    curl \
    iptables \
    iputils \
    sudo \
    nano \
    bridge-utils \
    dhcp \
    tcpdump \
    openvswitch \
    iperf3 \
    vim


#Install isc-dhcp-server
#RUN apt-get update
#RUN apt-get install isc-dhcp-server 
#RUN apt-get update
#RUN apt-get install isc-dhcp-relay

# open ports
# IPERF3
EXPOSE 8123:8123

