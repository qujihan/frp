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

# Download and set
wget --no-check-certificate -c ${download_url}
tar zxvf ${download_filename}.tar.gz
mkdir -p ${config_path}

# Config file
cat <<EOF > ${download_filename}/frps.toml
bindPort = ${port}
EOF

# systemd service file
cat <<EOF | sudo tee /etc/systemd/system/frps.service > /dev/null
[Unit]
Description = frp server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = ${bin_path}/frps -c ${config_path}/frps.toml
Restart=always
RestartSec=2

[Install]
WantedBy = multi-user.target
EOF

# Move executable and start service
sudo cp ${download_filename}/frps ${bin_path}
sudo cp ${download_filename}/frps.toml ${config_path}
rm -rf ${download_filename}*

sudo systemctl start frps
sudo systemctl enable frps
