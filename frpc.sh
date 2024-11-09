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
cat <<EOF > ${download_filename}/frpc.toml
serverAddr = "${server_addr}"
serverPort = ${server_port}

[[proxies]]
name = "rdp"
type = "tcp"
localIP = "127.0.0.1"
localPort = 3389
remotePort = 20003

[[proxies]]
name = "ubuntu_ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 20004
EOF

sudo cp ${download_filename}/frpc ${bin_path}
sudo cp ${download_filename}/frpc.toml ${config_path}
rm -rf ${download_filename}*

# systemctl
cat <<EOF | sudo tee /etc/systemd/system/frpc.service > /dev/null
[Unit]
Description = frp client
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = ${bin_path}/frpc -c ${config_path}/frpc.toml
Restart=always
RestartSec=2

[Install]
WantedBy = multi-user.target
EOF

sudo systemctl start frpc
sudo systemctl enable frpc
