FROM alpine:3.19

# 安装依赖
RUN apk add --no-cache \
    wireguard-tools \
    wireguard-go \
    openssh \
    bash \
    qrencode \
    curl \
    jq

# 配置 SSH
RUN ssh-keygen -A && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# 创建 wireguard 配置目录
RUN mkdir -p /etc/wireguard /root/.ssh

# 创建启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 创建客户端配置生成脚本
COPY generate-peer.sh /generate-peer.sh
RUN chmod +x /generate-peer.sh

EXPOSE 22 51820/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD pgrep -x sshd && pgrep -x wireguard-go || exit 1

ENTRYPOINT ["/entrypoint.sh"]
