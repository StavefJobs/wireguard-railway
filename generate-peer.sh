#!/bin/bash
# 生成 WireGuard 客户端配置

PEER_NAME=${1:-peer1}
WG_DIR="/etc/wireguard"
SERVER_CONF="$WG_DIR/wg0.conf"
SERVER_PUB_KEY_FILE="$WG_DIR/server_public_key"

if [ ! -f "$SERVER_PUB_KEY_FILE" ]; then
    echo "Error: Server public key not found. Start the container first."
    exit 1
fi

SERVER_PUBLIC_KEY=$(cat "$SERVER_PUB_KEY_FILE")

# 读取服务器配置获取端口和地址
SERVER_PORT=$(grep "ListenPort" "$SERVER_CONF" | awk '{print $3}')
SERVER_ADDRESS=$(grep "Address" "$SERVER_CONF" | awk '{print $3}')

# 提取网络地址（去掉子网掩码）
NETWORK=$(echo "$SERVER_ADDRESS" | cut -d'/' -f1 | cut -d'.' -f1-3)

# 生成客户端密钥对
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# 分配客户端 IP（简单的递增逻辑）
PEER_NUM=$(echo "$PEER_NAME" | grep -oE '[0-9]+$' || echo "1")
CLIENT_IP="${NETWORK}.$((PEER_NUM + 1))/32"

# 生成客户端配置
CLIENT_CONF="$WG_DIR/${PEER_NAME}.conf"
cat > "$CLIENT_CONF" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = <SERVER_ENDPOINT>:$SERVER_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "Client configuration generated: $CLIENT_CONF"
echo "Client public key: $CLIENT_PUBLIC_KEY"
echo ""
echo "NOTE: Replace <SERVER_ENDPOINT> with your Fly.io app address (e.g., your-app.fly.dev)"
echo "You can find the endpoint after deployment with: fly info"

# 将客户端公钥添加到服务器配置（需要重启 wg 才能生效）
echo "" >> "$SERVER_CONF"
echo "# Peer: $PEER_NAME" >> "$SERVER_CONF"
echo "[Peer]" >> "$SERVER_CONF"
echo "PublicKey = $CLIENT_PUBLIC_KEY" >> "$SERVER_CONF"
echo "AllowedIPs = $CLIENT_IP" >> "$SERVER_CONF"

echo "Client public key added to server config. Restart WireGuard to apply."
