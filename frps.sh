#!/bin/bash

# Parse input arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -port) port="$2"; shift ;;
        -version) frp_version="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check
if [[ -z "$port" || -z "$frp_version" ]]; then
    echo "Usage: $0 -port xxxx -version x.x.x"
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
echo "bindPort = {$port}" > ${download_filename}/frps.toml

# systemctl
touch frps.service
echo "[Unit]" > frps.service
echo "Description = frp server" >> frps.service
echo "After = network.target syslog.target" >> frps.service
echo "Wants = network.target" >> frps.service
echo "[Service]" >> frps.service
echo "Type = simple" >>frps.service
echo "ExecStart = ${bin_path}/frps -c ${config_path}/frps.toml" >> frps.service
echo "Restart=always" >> frps.service
echo "RestartSec=2" >> frps.service
echo "[Install]" >> frps.service
echo "WantedBy = multi-user.target" >> frps.service
sudo mv frps.service /etc/systemd/system


sudo systemctl start frps
sudo systemctl enable frps
