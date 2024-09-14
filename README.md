# Frp服务

## 如果需要配置代理
```bash
sudo apt install curl 
proxy_url="https://mirror.ghproxy.com"
```

## 在服务端
```bash
curl -Lo frps.sh ${proxy_url}/https://raw.githubusercontent.com/qujihan/frp/main/frps.sh 
sudo bash frps.sh -port 7000 -version 0.58.1
```

## 在客户端
```bash
curl -Lo frpc.sh ${proxy_url}/https://raw.githubusercontent.com/qujihan/frp/main/frpc.sh 
sudo bash frpc.sh -server x.x.x.x -port 7000 -version 0.58.1 
```