# xray4vps

This script installs and configures Xray on your VPS.

## 使用方法

1. 将脚本保存为 `install.sh`，上传到你的 VPS。
2. 修改脚本开头的以下变量：
   - `UUID`：设置 Xray 的 UUID。
   - `DOMAIN`：设置你的域名。
   - `PASSWORD`：设置你的密码。
3. 执行以下命令：

    ```bash
    sudo bash install.sh
    ```

### 配置说明

- **系统更新**：更新系统和软件包。
- **BBR 配置**：启用 TCP BBR 拥塞控制。
- **Xray 安装**：下载并配置 Xray 服务。
- **Nginx 配置**：配置 Nginx 监听 80 端口并代理到 Xray。
- **SSL 证书**：使用 Certbot 为 `jp.wavetransformer.ink` 域名申请 SSL 证书。

### 生成配置

脚本会生成一个 `cfw_config.yaml` 文件，内容包括：
- **代理配置**：连接到 Xray 服务。
- **代理组**：自动选择 Xray Proxy。
- **规则配置**：国内流量直连，国外流量通过代理。

导入该配置文件到 **Clash for Windows** 客户端，即可完成配置。
