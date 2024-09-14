#!/bin/bash

# Parse input arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -server) server_addr="$2"; shift ;;
        -port) server_port="$2"; shift ;;
        -version) frp_version="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check
if [[ -z "$server_addr" || -z "$server_port" || -z "$frp_version" ]]; then
    echo "Usage: $0 -server x.x.x.x -port xxxx -version x.x.x"
    exit 1
fi

# set user home
if [[ -n "$SUDO_USER" ]]; then
    user_home=$(eval echo "~$SUDO_USER")
else
    user_home="$HOME"
fi
bin_path="/usr/bin"
config_path="${user_home}/.config/frp"


download_filename="frp_${frp_version}_linux_amd64"
if [[ -n "$proxy_url" ]]; then
    download_url=${proxy_url}/https://github.com/fatedier/frp/releases/download/v${frp_version}/${download_filename}.tar.gz
else 
    download_url=https://github.com/fatedier/frp/releases/download/v${frp_version}/${download_filename}.tar.gz
fi 

# download and set
wget --no-check-certificate -c ${download_url}
tar zxvf ${download_filename}.tar.gz
mkdir -p ${config_path}

# config file
echo "serverAddr = \"${server_addr}\"" > ${download_filename}/frpc.toml
echo "serverPort = ${server_port}" >> ${download_filename}/frpc.toml

echo "  " >> ${download_filename}/frpc.toml
echo "[[proxies]]" >> ${download_filename}/frpc.toml
echo "name = \"rdp\"" >> ${download_filename}/frpc.toml
echo "type = \"tcp\"" >> ${download_filename}/frpc.toml
echo "localIP = \"127.0.0.1\"" >> ${download_filename}/frpc.toml
echo "localPort = 3389" >> ${download_filename}/frpc.toml
echo "remotePort = 20003" >> ${download_filename}/frpc.toml

echo "  " >> ${download_filename}/frpc.toml
echo "[[proxies]]" >> ${download_filename}/frpc.toml
echo "name = \"ubuntu_ssh\"" >> ${download_filename}/frpc.toml
echo "type = \"tcp\"" >> ${download_filename}/frpc.toml
echo "localIP = \"127.0.0.1\"" >> ${download_filename}/frpc.toml
echo "localPort = 22" >> ${download_filename}/frpc.toml
echo "remotePort = 20004" >> ${download_filename}/frpc.toml

sudo cp ${download_filename}/frpc ${bin_path}
sudo cp ${download_filename}/frpc.toml ${config_path}
rm -rf ${download_filename}*

# systemctl
touch frpc.service
echo "[Unit]" > frpc.service
echo "Description = frp client" >> frpc.service
echo "After = network.target syslog.target" >> frpc.service
echo "Wants = network.target" >> frpc.service
echo "[Service]" >> frpc.service
echo "Type = simple" >>frpc.service
echo "ExecStart = ${bin_path}/frpc -c ${config_path}/frpc.toml" >> frpc.service
echo "Restart=always" >> frpc.service
echo "RestartSec=2" >> frpc.service
echo "[Install]" >> frpc.service
echo "WantedBy = multi-user.target" >> frpc.service
sudo mv frpc.service /etc/systemd/system

sudo systemctl start frpc
sudo systemctl enable frpc
