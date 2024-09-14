# Frp服务

## 在服务端
```bash
sudo bash frps.sh -port 7000 -version 0.58.1 -proxy https://mirror.ghproxy.com
```

## 在客户端
```bash
sudo bash frpc.sh -server x.x.x.x -port 7000 -version 0.58.1 -proxy https://mirror.ghproxy.com
```