# Debian 13 SSH on Railway

基于 Debian 13 (trixie) 的 SSH 服务器，可部署在 Railway 平台。

## ✨ 功能特性

- 🐧 **Debian 13 (trixie)** 基础镜像（约 57MB，精简高效）
- 🔒 **SSH 访问**（root 用户，密码认证）
- 🌐 支持 Railway 全球部署
- 💾 **SSH 密钥持久化**（通过 Railway 卷挂载）

## 📋 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ROOT_PASSWORD` | `changeme` | root 用户密码 |
| `TZ` | `Etc/UTC` | 时区设置 |

## 🚀 Railway 部署步骤

### 1. 安装 Railway CLI

**macOS / Linux:**
```bash
npm install -g @railway/cli
```

**Windows (PowerShell):**
```powershell
iwr https://railway.app/install.ps1 -useb | iex
```

### 2. 登录 Railway

```bash
railway login
```

### 3. 初始化项目

```bash
railway init
```

- 选择 "Create new project" 或关联到现有项目
- 输入项目名称（如 `debian13-ssh`）

### 4. 创建持久化卷（可选，用于 SSH 密钥）

在 Railway 控制台中：
1. 进入项目设置
2. 添加 Volume，挂载到 `/root/.ssh`
3. 设置大小为 1GB

### 5. 设置环境变量（可选）

```bash
# 设置 root 密码（建议使用强密码）
railway variables set ROOT_PASSWORD="your-strong-password"

# 设置时区（可选）
railway variables set TZ="Asia/Shanghai"
```

### 6. 部署应用

```bash
railway up
```

部署过程会：
- 构建基于 Debian 13 的 Docker 镜像
- 启动 SSH 服务
- 配置 root 密码

### 7. 查看部署状态

```bash
railway status
railway logs
```

## 🔌 SSH 连接

### 方式一：使用密码认证

```bash
# 替换 your-app.railway.app 为你的应用地址
ssh root@your-app.railway.app

# 输入密码（默认 changeme，或你设置的 ROOT_PASSWORD）
```

### 方式二：使用密钥认证（推荐）

1. **生成 SSH 密钥对**（如果还没有）：
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

2. **将公钥添加到容器**：
   - 方法一：通过 Railway 环境变量
     ```bash
     railway variables set PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
     ```
     然后在 Dockerfile 中添加密钥处理逻辑。
   
   - 方法二：进入容器手动添加
     ```bash
     railway shell
     mkdir -p /root/.ssh
     echo "your-public-key-content" >> /root/.ssh/authorized_keys
     chmod 700 /root/.ssh
     chmod 600 /root/.ssh/authorized_keys
     ```

3. **使用密钥连接**：
   ```bash
   ssh -i ~/.ssh/id_ed25519 root@your-app.railway.app
   ```

## 📁 文件位置

容器内重要目录：
- `/etc/ssh/` - SSH 配置文件
- `/root/.ssh/` - SSH 密钥目录（如果挂载了卷）
- `/var/log/auth.log` - SSH 认证日志

## 🛠️ 管理操作

### 查看运行日志

```bash
railway logs
```

### 进入容器 Shell

```bash
railway shell
```

### 重启服务

```bash
railway up  # 重新部署
```

### 查看应用信息

```bash
railway status
railway domain
```

## 🔒 安全建议

1. **修改默认密码**：部署后立即设置强密码
   ```bash
   railway variables set ROOT_PASSWORD="your-very-strong-password"
   ```

2. **使用 SSH 密钥**：禁用密码认证，仅使用密钥
   - 挂载 `authorized_keys` 到 `/root/.ssh/`
   - 在 `sshd_config` 中设置 `PasswordAuthentication no`

3. **定期更新**：重新部署以获取最新的 Debian 和安全补丁
   ```bash
   railway up
   ```

## 💰 成本估算

Railway 定价：
- **免费额度**：有限的使用额度
- **Hobby 计划**：$5/月（包含 $5 额度）
- **Pro 计划**：$20/月起

对于简单的 SSH 服务器使用，可以考虑使用 Railway 的免费额度或 Hobby 计划。

## 🐛 故障排查

### SSH 连接失败

1. 检查密码是否正确
2. 查看 SSH 服务是否运行：`railway shell` 后执行 `ps aux | grep sshd`
3. 检查 Railway 日志：`railway logs`

### 无法登录

1. 查看日志：`railway logs`
2. 检查 `sshd_config` 配置是否正确
3. 确认 root 密码已设置：`railway variables get ROOT_PASSWORD`

### 时区不正确

```bash
railway variables set TZ="Asia/Shanghai"
railway up
```

## 📚 参考资源

- [Debian 13 官方镜像](https://hub.docker.com/r/tchung1970/d13)
- [Railway 文档](https://docs.railway.app/)
- [takeyamajp/docker-debian-sshd](https://github.com/takeyamajp/docker-debian-sshd)（参考项目）

## 📄 License

MIT License

---

**基于 [tchung1970/d13](https://github.com/tchung1970/d13) 和 [takeyamajp/docker-debian-sshd](https://github.com/takeyamajp/docker-debian-sshd) 构建**

**由 opencode 自动生成** 🚀
