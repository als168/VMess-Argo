#!/bin/bash
# =========================================================
# Xray + Argo 修复版 (V6.0)
# =========================================================

# set -e 

# === 变量 ===
PORT=8001
WORKDIR="/etc/xray_optimized"
CONFIG_FILE="$WORKDIR/config.json"
XRAY_BIN="/usr/local/bin/xray"
CF_BIN="/usr/local/bin/cloudflared"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# === 环境检测 ===
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}请使用 root 运行!${PLAIN}"
        exit 1
    fi
}

detect_system() {
    if [ -f /etc/alpine-release ]; then
        OS="alpine"
        INIT="openrc"
        PKG_CMD="apk add --no-cache"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        INIT="systemd"
        PKG_CMD="apt-get update && apt-get install -y"
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
        INIT="systemd"
        PKG_CMD="yum install -y"
    else
        echo -e "${RED}不支持的系统${PLAIN}"
        exit 1
    fi
}

detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  X_ARCH="64"; C_ARCH="amd64" ;;
        aarch64) X_ARCH="arm64-v8a"; C_ARCH="arm64" ;;
        *) echo -e "${RED}不支持的架构: $ARCH${PLAIN}"; exit 1 ;;
    esac
}

# === 优化与安装 ===
optimize_env() {
    MEM=$(free -m | awk '/Mem:/ { print $2 }')
    if [ "$MEM" -le 384 ]; then
        if [ ! -f /swapfile ]; then
            dd if=/dev/zero of=/swapfile bs=1M count=512 status=none || true
            chmod 600 /swapfile
            mkswap /swapfile >/dev/null 2>&1 || true
            swapon /swapfile >/dev/null 2>&1 || true
        fi
    fi
    echo -e "${YELLOW}安装依赖...${PLAIN}"
    $PKG_CMD curl wget unzip jq coreutils ca-certificates >/dev/null 2>&1
    [ "$OS" == "alpine" ] && apk add --no-cache libgcc bash grep >/dev/null 2>&1
}

install_bins() {
    mkdir -p $WORKDIR
    detect_arch

    if [ ! -f "$XRAY_BIN" ]; then
        echo -e "${YELLOW}下载 Xray...${PLAIN}"
        TAG=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r .tag_name)
        [ -z "$TAG" ] || [ "$TAG" = "null" ] && TAG="v1.8.4"
        # 确保下载链接正确
        curl -L -o xray.zip "https://github.com/XTLS/Xray-core/releases/download/$TAG/Xray-linux-$X_ARCH.zip"
        unzip -qo xray.zip -d $WORKDIR
        mv $WORKDIR/xray $XRAY_BIN
        chmod +x $XRAY_BIN
        rm -f xray.zip $WORKDIR/geoip.dat $WORKDIR/geosite.dat
    fi

    if [ ! -f "$CF_BIN" ]; then
        echo -e "${YELLOW}下载 Cloudflared...${PLAIN}"
        curl -L -o $CF_BIN "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$C_ARCH"
        chmod +x $CF_BIN
    fi
}

config_xray() {
    UUID=$(cat /proc/sys/kernel/random/uuid)
    cat > $CONFIG_FILE <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": $PORT,
    "listen": "127.0.0.1",
    "protocol": "vmess",
    "settings": { "clients": [{ "id": "$UUID" }] },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
}

setup_service() {
    MODE=$1
    TOKEN_OR_URL=$2

    if [ "$INIT" == "systemd" ]; then
        systemctl stop xray_opt cloudflared_opt 2>/dev/null || true
    else
        rc-service xray_opt stop 2>/dev/null || true
        rc-service cloudflared_opt stop 2>/dev/null || true
    fi

    if [ "$INIT" == "systemd" ]; then
        cat > /etc/systemd/system/xray_opt.service <<EOF
[Unit]
Description=Xray
After=network.target
[Service]
Environment="GOGC=20"
ExecStart=$XRAY_BIN -c $CONFIG_FILE
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
        if [ "$MODE" == "fixed" ]; then
            CF_EXEC="$CF_BIN tunnel run --token $TOKEN_OR_URL"
        else
            CF_EXEC="$CF_BIN tunnel --url http://localhost:$PORT --no-autoupdate --protocol http2"
        fi
        cat > /etc/systemd/system/cloudflared_opt.service <<EOF
[Unit]
Description=Cloudflared
After=network.target xray_opt.service
[Service]
Environment="GOGC=20"
ExecStart=$CF_EXEC
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable xray_opt cloudflared_opt >/dev/null 2>&1
        systemctl restart xray_opt cloudflared_opt

    elif [ "$INIT" == "openrc" ]; then
        cat > /etc/init.d/xray_opt <<EOF
#!/sbin/openrc-run
description="Xray"
command="$XRAY_BIN"
command_args="-c $CONFIG_FILE"
command_background="yes"
pidfile="/run/xray_opt.pid"
depend() { need net; }
start_pre() { export GOGC=20; }
EOF
        chmod +x /etc/init.d/xray_opt
        
        if [ "$MODE" == "fixed" ]; then
            CF_ARGS="tunnel run --token $TOKEN_OR_URL"
        else
            CF_ARGS="tunnel --url http://localhost:$PORT --no-autoupdate --protocol http2"
        fi
        
        cat > /etc/init.d/cloudflared_opt <<EOF
#!/sbin/openrc-run
description="Cloudflared"
command="$CF_BIN"
command_args="$CF_ARGS"
command_background="yes"
pidfile="/run/cloudflared_opt.pid"
depend() { need net; after xray_opt; }
start_pre() { export GOGC=20; }
EOF
        chmod +x /etc/init.d/cloudflared_opt

        rc-update add xray_opt default >/dev/null
        rc-update add cloudflared_opt default >/dev/null
        rc-service xray_opt restart
        rc-service cloudflared_opt restart
    fi
}

show_result() {
    echo ""
    echo -e "${GREEN}Xray + Argo 安装成功!${PLAIN}"
    echo -e "域名: ${YELLOW}$DOMAIN${PLAIN}"
    echo -e "UUID: ${YELLOW}$UUID${PLAIN}"
    
    VMESS_JSON="{\"v\":\"2\",\"ps\":\"Argo-${DOMAIN}\",\"add\":\"$DOMAIN\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$DOMAIN\",\"path\":\"/vmess\",\"tls\":\"tls\",\"sni\":\"$DOMAIN\"}"
    VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"
    echo -e "${GREEN}链接:${PLAIN} $VMESS_LINK"
    
    if [ "$MODE" == "fixed" ]; then
        echo -e "${RED}重要提示:${PLAIN} Cloudflare 后台 Service 必须设为: HTTP -> localhost:8001"
    fi
}

# === 菜单 ===
check_root
detect_system

clear
echo "------------------------------------------------"
echo "1. 固定隧道 (Token)"
echo "2. 临时隧道"
echo "------------------------------------------------"
read -p "选择: " choice < /dev/tty

case "$choice" in
    1)
        read -p "输入 Token: " TOKEN < /dev/tty
        [ -z "$TOKEN" ] && exit 1
        read -p "输入域名: " DOMAIN < /dev/tty
        MODE="fixed"
        optimize_env
        install_bins
        config_xray
        setup_service "fixed" "$TOKEN"
        show_result
        ;;
    2)
        echo "暂不支持，请用固定隧道"
        exit 0
        ;;
esac
