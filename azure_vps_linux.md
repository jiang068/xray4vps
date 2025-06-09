# (Linux篇)申请 Azure for Students

并获取多年免费 VPS 并搭建访外线路。

如果你有一个 .edu 或 .edu.cn 邮箱为何不试一试呢。

## 1. 访问 Azure Students

点击 "免费开始使用" ，一步一步按照指引填写你的学校邮箱即可。

参考文章：[Azure 学生账号申请教程](https://zhuanlan.zhihu.com/p/629311513)

## 2. 创建免费 Linux 虚拟机

访问连接：[Create Free Linux VM](https://portal.azure.com/#create/microsoft.freeaccountvirtualmachine-linux)

直接点 "创建"。
![创建](./pics/pic1.png)

按照图示填写虚拟机信息，
![填写](./pics/pic2.png)

点击 "查看+创建"即可。
![查看+创建](./pics/pic3.png)

## 3. 连接到你的虚拟机

访问 Azure 虚拟机面板：[https://portal.azure.com/#browse/Microsoft.Compute%2FVirtualMachines](https://portal.azure.com/#browse/Microsoft.Compute%2FVirtualMachines)

如果没有域名，可以创建 DNS 配置，使用 DNS 地址代替 IP 地址。
![IP](./pics/pic4.png)

点击配置后可以自选一个域名来代替你的公共ip：
![IP2](./pics/pic5.png)
回到本机，打开 CMD ，输入

```sh
ssh 用户名@DNS地址
```
![ssh](./pics/pic6.png)
然后输入你的密码就好，没有回显，放心输入后回车即可。

如果未安装 SSH 请先安装 SSH。

## 4. 安装 Xray + Nginx + Certbot (推荐配置)

### 4.0 更新程序包

```sh
sudo apt update     # 更新软件列表
sudo apt upgrade    # 升级已安装的软件
```

### 4.1 安装 Xray

参考官方文档：[https://xtls.github.io/document/install.html](https://xtls.github.io/document/install.html)

安装命令：

```sh
sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
```

Xray 的配置文件默认位置：

```text
/usr/local/etc/xray/config.json
```

**配置示例**(请使用自己生成的 UUID 和域名，删除此处示例中的真实数据)：

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 3001,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {"id": "<uuid-vless>"}
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vlessws"
        }
      }
    },
    {
      "port": 3002,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {"password": "<uuid-trojan>"}
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojanws"
        }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 51410,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {"password": "<uuid-cert>", "level": 0}
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/<your-domain>/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/<your-domain>/privkey.pem"
            }
          ]
        },
        "tcpSettings": {
          "acceptProxyProtocol": false
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
```

**注意**：Xray 的 config.json 不支持注释。

### 4.2 安装 Nginx

```sh
sudo apt install nginx
```

配置 nginx.conf ：

```conf
http {
    include /etc/nginx/conf.d/*.conf;
    # ... 其他配置
}
```

在 `/etc/nginx/conf.d/` 新建 `xray.conf`：

```conf
server {
    listen 80;
    server_name <your-domain>;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name <your-domain>;

    ssl_certificate /etc/letsencrypt/live/<your-domain>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/<your-domain>/privkey.pem;

    location / {
        root /var/www/html;
        index index.html;
    }

    location /vlessws {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location /trojanws {
        proxy_pass http://127.0.0.1:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

### 4.3 安装 Certbot
cetbot负责为你的域名申请ssl证书。如果没有证书你的vps只能用sw协议传输数据，几乎等于明文所以安全性不能保证。Trojan和Vless等协议都需要对应域名的ssl证书。这个和网站的https的访问所用到的ssl证书是一个东西。

以下是在 Ubuntu + Nginx 环境下，使用 Certbot 安装并申请 Let's Encrypt 免费 SSL 证书 的完整流程。

**一、前提条件**
Ubuntu 已安装好 Nginx 并运行。

你拥有一个已解析到这台服务器公网 IP 的域名（如 example.com）。

可在自己的电脑上用命令检查：

```bash
ping example.com
```
**二、安装 Certbot 和 Nginx 插件**
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```
**三、使用 Certbot 自动为 Nginx 配置 HTTPS**

Certbot 会自动识别 Nginx 配置并签发证书：

```bash
sudo certbot --nginx
```
安装过程中会提示你：

输入邮箱（用于续期通知）。

是否同意服务条款（选 A 同意）。

是否强制跳转到 HTTPS（建议选 2）。

**四、申请成功后，访问验证**
申请成功后，Certbot 会自动修改你的 Nginx 配置，开启 443 端口，并启用 HTTPS。

你现在可以访问:https://example.com

验证是否有绿锁图标和有效证书。

有可能你需要重启一次nginx.

**五、测试自动续期**
Let's Encrypt 证书有效期为 90 天，Certbot 默认每天自动检查是否需要续期。

你可以手动测试自动续期是否成功：

```bash
sudo certbot renew --dry-run
```
不过我建议你证书能用就不要再动，等到了90天再说。并且最近更新了协议，免费证书有效期即将缩短到51天了。所以要时不时检查。
**六、Nginx 默认配置结构示例（即伪装页）**
```nginx
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    location / {
        root /var/www/html;
        index index.html index.htm;
    }
    # 其他location, 如vless和Trojan的入口，前面已有配置可以参考。
}
```
这里注意，`/var/www/html`是你网站文件的所在位置，主页一般是`index.html`文件。如果你没有记得放点东西进去，比如可以问ai要一个简单的html网页改名index放进去就行了。
