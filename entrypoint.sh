#!/bin/bash
set -e

echo "=== WireGuard + SSH Container Starting ==="

# 配置 SSH
if [ -n "$SSH_PASSWORD" ]; then
    echo "root:$SSH_PASSWORD" | chpasswd
    echo "[SSH] Password set from environment variable"
else
    echo "root:changeme" | chpasswd
    echo "[SSH] Using default password: changeme"
fi

# 如果挂载了 SSH 公钥，启用密钥认证
if [ -f /root/.ssh/authorized_keys ]; then
    chmod 600 /root/.ssh/authorized_keys
    echo "[SSH] SSH public key mounted, key authentication enabled"
fi

# 启动 SSH 服务
/usr/sbin/sshd -D &
echo "[SSH] SSH service started on port 22"

# 生成或加载 WireGuard 配置
WG_CONF="/etc/wireguard/wg0.conf"

if [ ! -f "$WG_CONF" ]; then
    echo "[WireGuard] Generating server configuration..."
    
    # 生成服务器私钥
    if [ -z "$WG_PRIVATE_KEY" ]; then
        WG_PRIVATE_KEY=$(wg genkey)
        echo "[WireGuard] Generated new private key"
    fi
    
    WG_PUBLIC_KEY=$(echo "$WG_PRIVATE_KEY" | wg pubkey)
    WG_ADDRESS=${WG_ADDRESS:-"10.7.0.1/24"}
    WG_PORT=${WG_PORT:-51820}
    
    # 生成服务器配置
    cat > "$WG_CONF" << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_ADDRESS
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
    
    # 保存公钥供客户端使用
    echo "$WG_PUBLIC_KEY" > /etc/wireguard/server_public_key
    echo "[WireGuard] Server public key: $WG_PUBLIC_KEY"
    
    # 生成默认客户端配置
    /generate-peer.sh peer1
fi

# 启动 WireGuard（优先使用 wireguard-go 用户空间实现）
echo "[WireGuard] Starting WireGuard..."

# 尝试使用 wireguard-go（用户空间，无需内核模块）
if command -v wireguard-go &> /dev/null; then
    echo "[WireGuard] Using wireguard-go (userspace implementation)"
    wireguard-go wg0 &
    WG_PID=$!
    sleep 2
    
    if ps -p $WG_PID > /dev/null; then
        echo "[WireGuard] wireguard-go started successfully (PID: $WG_PID)"
    else
        echo "[WireGuard] wireguard-go failed, trying kernel module..."
        wg-quick up wg0
    fi
else
    echo "[WireGuard] wireguard-go not found, using kernel module..."
    wg-quick up wg0
fi

echo "[WireGuard] WireGuard started on port ${WG_PORT:-51820}"

# 显示客户端配置
if [ -f /etc/wireguard/peer1.conf ]; then
    echo ""
    echo "=== Client Configuration (peer1) ==="
    cat /etc/wireguard/peer1.conf
    echo ""
    
    if command -v qrencode &> /dev/null; then
        echo "=== QR Code for peer1 (scan with WireGuard app) ==="
        qrencode -t ansiutf8 < /etc/wireguard/peer1.conf
    fi
fi

echo ""
echo "=== Container Ready ==="
echo "SSH: ssh root@<your-app>.fly.dev"
echo "WireGuard: Import peer1.conf or scan QR code"
echo ""

# 保持容器运行
tail -f /dev/null
