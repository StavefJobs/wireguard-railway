# Debian 13 SSH on Fly.io

基于 Debian 13 (trixie) 的 SSH 服务器，可部署在 Fly.io 平台。

## ✨ 功能特性

- 🐧 **Debian 13 (trixie)** 基础镜像（约 57MB，精简高效）
- 🔒 **SSH 访问**（root 用户，密码认证）
- 🌐 **全球部署**（Fly.io 边缘网络，自动选择最近节点）
- 💾 **SSH 密钥持久化**（通过 Fly.io 卷挂载）

## 📋 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ROOT_PASSWORD` | `changeme` | root 用户密码 |
| `TZ` | `Etc/UTC` | 时区设置 |

## 🚀 Fly.io 部署步骤

### 1. 登录 Fly.io

```bash
fly auth login
```

### 2. 初始化应用（不立即部署）

```bash
fly launch --no-deploy --region sin
```

- 选择应用名称（或按 Enter 使用随机名称）
- 选择组织（通常是个人）
- 当询问是否立即部署时，选择 **N**

### 3. 创建持久化卷（用于 SSH 密钥）

```bash
fly volumes create ssh_data --size 1
```

此卷用于持久化 `/root/.ssh` 目录，保存 SSH 密钥配置。

### 4. 设置环境变量（可选）

```bash
# 设置 root 密码（建议使用强密码）
fly secrets set ROOT_PASSWORD="your-strong-password"

# 设置时区（可选）
fly secrets set TZ="Asia/Shanghai"
```

### 5. 部署应用

```bash
fly deploy
```

部署过程会：
- 构建基于 Debian 13 的 Docker 镜像
- 启动 SSH 服务
- 配置 root 密码

### 6. 查看部署状态

```bash
fly status
fly logs
```

## 🔌 SSH 连接

### 使用密码认证

```bash
# 替换 your-app 为你的应用名称
ssh root@your-app.fly.dev

# 输入密码（默认 changeme，或你设置的 ROOT_PASSWORD）
```

### 使用密钥认证（推荐）

1. **生成 SSH 密钥对**（如果还没有）：
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

2. **将公钥添加到容器**：
   - 方法一：通过环境变量（需要重启）
     ```bash
     fly secrets set PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
     ```
     然后在 Dockerfile 中添加密钥处理逻辑。
   
   - 方法二：进入容器手动添加
     ```bash
     fly ssh console
     mkdir -p /root/.ssh
     echo "your-public-key-content" >> /root/.ssh/authorized_keys
     chmod 700 /root/.ssh
     chmod 600 /root/.ssh/authorized_keys
     ```

3. **使用密钥连接**：
   ```bash
   ssh -i ~/.ssh/id_ed25519 root@your-app.fly.dev
   ```

## 📁 文件位置

容器内重要目录：
- `/etc/ssh/` - SSH 配置文件
- `/root/.ssh/` - SSH 密钥目录（持久化卷）
- `/var/log/auth.log` - SSH 认证日志

## 🛠️ 管理操作

### 查看运行日志

```bash
fly logs
```

### SSH 进入容器

```bash
fly ssh console
```

### 重启服务

```bash
fly machines restart <machine-id>
# 或
fly deploy  # 重新部署
```

### 查看应用信息

```bash
fly info
fly status
```

### 查看 IP 地址

```bash
fly ips list
```

## 🔒 安全建议

1. **修改默认密码**：部署后立即设置强密码
   ```bash
   fly secrets set ROOT_PASSWORD="your-very-strong-password"
   ```

2. **使用 SSH 密钥**：禁用密码认证，仅使用密钥
   - 挂载 `authorized_keys` 到 `/root/.ssh/`
   - 在 `sshd_config` 中设置 `PasswordAuthentication no`

3. **定期更新**：重新部署以获取最新的 Debian 和安全补丁
   ```bash
   fly deploy
   ```

4. **限制访问**：考虑配置防火墙规则或使用 Fly.io 的 Private Networking

## 💰 成本估算

Fly.io 定价（2026）：
- **免费额度**：每月 3 个共享 CPU，256MB RAM 的机器，234,000 秒运行时间
- **小型实例**：`shared-cpu-1x` (256MB) ≈ $1.94/月
- **卷存储**：$0.15/GB/月（1GB 卷 ≈ $0.15/月）

对于简单的 SSH 服务器使用，通常在免费额度内。

## 🐛 故障排查

### SSH 连接失败

1. 检查密码是否正确
2. 查看 SSH 服务是否运行：`fly ssh console` 后执行 `ps aux | grep sshd`
3. 检查防火墙规则：`fly ips list`

### 无法登录

1. 查看日志：`fly logs`
2. 检查 `sshd_config` 配置是否正确
3. 确认 root 密码已设置：`fly secrets list`

### 时区不正确

```bash
fly secrets set TZ="Asia/Shanghai"
fly deploy
```

## 📚 参考资源

- [Debian 13 官方镜像](https://hub.docker.com/r/tchung1970/d13)
- [Fly.io 文档](https://fly.io/docs/)
- [takeyamajp/docker-debian-sshd](https://github.com/takeyamajp/docker-debian-sshd)（参考项目）

## 📄 License

MIT License

---

**基于 [tchung1970/d13](https://github.com/tchung1970/d13) 和 [takeyamajp/docker-debian-sshd](https://github.com/takeyamajp/docker-debian-sshd) 构建**

**由 opencode 自动生成** 🚀
