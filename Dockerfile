FROM tchung1970/d13:latest

# 安装 SSH 服务器
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 创建 SSH 运行目录
RUN mkdir -p /run/sshd

# 配置 SSH：允许 root 登录和密码认证
RUN sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/#UsePAM yes/' /etc/ssh/sshd_config

# 创建 entrypoint 脚本
RUN { \
    echo '#!/bin/bash -e'; \
    echo 'ln -fs /usr/share/zoneinfo/${TZ:-Etc/UTC} /etc/localtime'; \
    echo 'echo "root:${ROOT_PASSWORD:-changeme}" | chpasswd'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# 设置环境变量
ENV TZ=Etc/UTC
ENV ROOT_PASSWORD=changeme

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
