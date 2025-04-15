#!/bin/bash

# 设置用户自定义变量：修改下面的值为你的 UUID 和域名
UUID="your-uuid-here"
DOMAIN="your-domain-here"
PASSWORD="your_password_here"

# 更新系统
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装必要的依赖
echo "安装必要的依赖..."
sudo apt install -y nginx curl unzip sudo lsof iproute2 sysctl

# 配置BBR
echo "启用BBR拥塞控制..."
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 安装Xray
echo "安装 Xray..."
curl -sSL https://github.com/xtls/xray-core/releases/latest/download/xray-linux-amd64.tar.gz | tar -xz -C /usr/local/bin

# 配置Xray服务
echo "配置 Xray 服务..."
sudo tee /etc/systemd/system/xray.service > /dev/null <<EOL
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray -config /etc/xray/config.json
Restart=on-failure
User=root
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOL

# 配置Nginx
echo "配置 Nginx..."
sudo tee /etc/nginx/sites-enabled/default > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        root /var/www/html;
        index index.html;
    }

    location /trojan {
        proxy_pass http://127.0.0.1:443;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
    }
}
EOL

# 配置 Xray 配置文件
echo "配置 Xray 配置文件..."
sudo tee /etc/xray/config.json > /dev/null <<EOL
{
    "inbounds": [
        {
            "port": 443,
            "listen": "0.0.0.0",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "$PASSWORD"
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem",
                            "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
                        }
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOL

# 安装 Certbot 和 Nginx 插件
echo "安装 Certbot 和 Nginx 插件..."
sudo apt install -y certbot python3-certbot-nginx

# 配置 SSL 证书
echo "配置 SSL 证书..."
sudo certbot --nginx -d $DOMAIN --agree-tos --non-interactive

# 重启Nginx和Xray服务
echo "重启 Nginx 和 Xray 服务..."
sudo systemctl restart nginx
sudo systemctl enable nginx
sudo systemctl start nginx

sudo systemctl enable xray
sudo systemctl start xray

# 确认服务状态
echo "确认服务状态..."
sudo systemctl status nginx
sudo systemctl status xray

# 输出用于 CFW 的 YAML 配置文件
echo "输出 CFW 配置文件..."
cat <<EOL > ~/cfw_config.yaml
Proxy:
  - name: "Xray Proxy"
    type: trojan
    server: $DOMAIN
    port: 443
    password: "$PASSWORD"
    udp: true
    sni: "$DOMAIN"
    tls: true
    skip-cert-verify: true
    alpn: "h2,http/1.1"
    use-proxy-protocol: true
    header:
      type: none

Proxy Group:
  - name: "Auto"
    type: select
    proxies:
      - "Xray Proxy"
    
Rule:
  - DOMAIN-SUFFIX,cn,DIRECT
  - DOMAIN-KEYWORD,google,PROXY
  - DOMAIN-SUFFIX,com,PROXY
  - DOMAIN-SUFFIX,net,PROXY
  - DOMAIN-SUFFIX,org,PROXY
  - IP-CIDR,8.8.8.8/32,PROXY
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
EOL

echo "CFW 配置文件已生成，路径：~/cfw_config.yaml"
echo "安装完成！"
