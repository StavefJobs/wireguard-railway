# WireGuard + SSH on Fly.io

基于 WireGuard 的用户空间实现（wireguard-go），在 Fly.io 上部署支持 SSH 访问的 VPN 服务器。

## ✨ 功能特性

- 🔒 **WireGuard VPN 服务器**（用户空间实现，无需内核模块）
- 🖥️ **SSH 访问**（root 用户，支持密码 + 密钥双认证）
- 📱 **自动生成客户端配置**（含二维码）
- 🌐 **全球部署**（Fly.io 边缘网络，自动选择最近节点）
- 💾 **配置持久化**（通过 Fly.io 卷挂载）

## 📋 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `SSH_PASSWORD` | 否 | `changeme` | SSH root 用户密码 |
| `WG_PRIVATE_KEY` | 否 | 自动生成 | WireGuard 服务器私钥（留空自动生成） |
| `WG_ADDRESS` | 否 | `10.7.0.1/24` | VPN 子网地址 |
| `WG_PORT` | 否 | `51820` | WireGuard 监听端口 |

## 🚀 Fly.io 部署步骤

### 1. 安装 Fly CLI

**macOS / Linux:**
```bash
curl -L https://fly.io/install.sh | sh
```

**Windows (PowerShell):**
```powershell
iwr https://fly.io/install.ps1 -useb | iex
```

### 2. 登录 Fly.io

```bash
fly auth login
```

### 3. 初始化应用（不立即部署）

```bash
fly launch --no-deploy --region sin
```

- 选择应用名称（或按 Enter 使用随机名称）
- 选择组织（通常是个人）
- 当询问是否立即部署时，选择 **N**

### 4. 创建持久化卷

```bash
fly volumes create wg_data --size 1
```

此卷用于持久化 WireGuard 配置（客户端配置、密钥等）。

### 5. 设置环境变量（可选）

```bash
# 设置 SSH 密码（建议使用强密码）
fly secrets set SSH_PASSWORD="your-strong-password"

# 如果需要自定义 WireGuard 配置
fly secrets set WG_ADDRESS="10.7.0.1/24"
fly secrets set WG_PORT="51820"

# 如果要使用固定的 WireGuard 私钥（可选，留空会自动生成）
# fly secrets set WG_PRIVATE_KEY="$(wg genkey)"
```

### 6. 部署应用

```bash
fly deploy
```

部署过程会：
- 构建 Docker 镜像
- 启动容器
- 自动生成 WireGuard 服务器密钥和客户端配置
- 启动 SSH 和 WireGuard 服务

### 7. 查看部署日志和客户端配置

```bash
fly logs
```

日志中会显示：
- ✅ 服务器公钥
- ✅ 客户端配置（peer1.conf）
- ✅ 二维码（可直接扫码导入到手机 WireGuard 应用）

### 8. 获取应用地址

```bash
fly info
```

记下 **HOSTNAME**（如 `your-app.fly.dev`），这是 WireGuard 客户端连接的端点。

### 9. 更新客户端配置

由于客户端配置中的 `<SERVER_ENDPOINT>` 需要替换为真实地址，执行：

```bash
fly ssh console
# 进入容器后执行：
sed -i "s/<SERVER_ENDPOINT>/$(fly info --json | jq -r .Hostname)/g" /etc/wireguard/peer1.conf
cat /etc/wireguard/peer1.conf
```

或者手动编辑本地的 `peer1.conf`，将 `<SERVER_ENDPOINT>` 替换为你的 Fly.io 应用地址。

## 🔌 客户端连接

### WireGuard VPN

1. **下载客户端**：
   - iOS/Android: 安装 WireGuard 官方应用
   - macOS/Windows/Linux: 安装 WireGuard 客户端

2. **导入配置**：
   - **方式 1（推荐）**：扫描日志中的二维码
   - **方式 2**：从容器复制配置
     ```bash
     fly ssh console
     cat /etc/wireguard/peer1.conf
     ```
     复制内容到本地 `peer1.conf`，然后导入到 WireGuard 客户端

3. **连接 VPN**：在 WireGuard 客户端中启用隧道

### SSH 访问

```bash
# 替换 your-app 为你的应用名称
ssh root@your-app.fly.dev

# 输入密码（默认 changeme，或你设置的 SSH_PASSWORD）
```

如果使用密钥认证，先将公钥挂载到 `/root/.ssh/authorized_keys`，然后：
```bash
ssh -i ~/.ssh/your_key root@your-app.fly.dev
```

## 📁 文件位置

容器内所有 WireGuard 相关文件位于 `/etc/wireguard/`：

```
/etc/wireguard/
├── wg0.conf              # WireGuard 服务器配置
├── server_public_key     # 服务器公钥
├── peer1.conf            # 客户端1配置
├── peer2.conf            # 客户端2配置（可用 generate-peer.sh 生成）
└── ...
```

## 🛠️ 管理操作

### 添加新的客户端

```bash
fly ssh console
/generate-peer.sh peer2
```

### 查看当前连接

```bash
fly ssh console
wg show
```

### 重启服务

```bash
fly machines restart <machine-id>
# 或
fly deploy  # 重新部署
```

### SSH 进入容器

```bash
fly ssh console
```

## 🔒 安全建议

1. **修改默认密码**：部署后立即设置强密码
   ```bash
   fly secrets set SSH_PASSWORD="your-very-strong-password"
   ```

2. **使用 SSH 密钥**：禁用密码认证，仅使用密钥
   - 挂载 `authorized_keys` 到 `/root/.ssh/`
   - 在 `sshd_config` 中设置 `PasswordAuthentication no`

3. **定期更新**：重新部署以获取最新的 Alpine 和安全补丁
   ```bash
   fly deploy
   ```

4. **限制 SSH 访问**：考虑使用 Fly.io 的 Private Networking 功能

## 💰 成本估算

Fly.io 定价（2026）：
- **免费额度**：每月 3 个共享 CPU，256MB RAM 的机器，234,000 秒运行时间
- **小型实例**：`shared-cpu-1x` (256MB) ≈ $1.94/月
- **卷存储**：$0.15/GB/月（1GB 卷 ≈ $0.15/月）

对于个人 VPN 使用，通常在免费额度内。

## 🐛 故障排查

### WireGuard 无法启动

查看日志：
```bash
fly logs
```

常见问题：
- **端口被占用**：确保 51820/UDP 未被其他服务占用
- **wireguard-go 失败**：检查日志，可能需要回退到内核模块

### SSH 连接失败

1. 检查密码是否正确
2. 查看 SSH 服务是否运行：`fly ssh console` 后执行 `ps aux | grep sshd`
3. 检查防火墙规则

### 客户端无法连接 VPN

1. 确认客户端配置中的 Endpoint 地址正确（应为 `your-app.fly.dev:51820`）
2. 检查 AllowedIPs 设置（默认 `0.0.0.0/0` 表示所有流量走 VPN）
3. 验证服务器公钥是否匹配

## 📚 参考资源

- [WireGuard 官方文档](https://www.wireguard.com/)
- [Fly.io 文档](https://fly.io/docs/)
- [wireguard-go GitHub](https://github.com/WireGuard/wireguard-go)

## 📄 License

MIT License

---

**由 opencode 自动生成** 🚀
