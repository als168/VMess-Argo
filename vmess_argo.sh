#!/usr/bin/env bash
set -euo pipefail

# ================== 默认参数 ==================
UUID="${UUID:-$(cat /proc/sys/kernel/random/uuid)}"
XRAY_PORT="${XRAY_PORT:-10080}"
WS_PATH="${WS_PATH:-/vmess}"
ARGO_TOKEN="${ARGO_TOKEN:-}"   # 留空则使用 Quick Tunnel

# ================== 安装依赖 ==================
install_xray() {
  if command -v xray >/dev/null 2>&1; then
    echo "[+] Xray 已存在"
    return
  fi
  echo "[+] 安装 Xray..."
  tmpdir="$(mktemp -d)"
  cd "$tmpdir"
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) dl_arch="64" ;;
    aarch64|arm64) dl_arch="arm64-v8a" ;;
    armv7l) dl_arch="arm32-v7a" ;;
    *) dl_arch="64" ;;
  esac
  url="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-$dl_arch.zip"
  curl -fsSL "$url" -o xray.zip
  unzip -q xray.zip
  install -m 755 xray /usr/local/bin/xray
  echo "[+] Xray 安装完成"
}

install_cloudflared() {
  if command -v cloudflared >/dev/null 2>&1; then
    echo "[+] cloudflared 已存在"
    return
  fi
  echo "[+] 安装 cloudflared..."
  arch="$(uname -m)"
  url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
  [ "$arch" = "aarch64" ] && url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
  curl -fsSL "$url" -o /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
  echo "[+] cloudflared 安装完成"
}

# ================== 写配置 ==================
write_xray_config() {
  mkdir -p /etc/xray
  cat > /etc/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $XRAY_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "$UUID", "alterId": 0 }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "$WS_PATH" }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
EOF
  echo "[+] Xray 配置写入 /etc/xray/config.json"
}

# ================== 启动服务 ==================
start_xray() {
  echo "[+] 启动 Xray..."
  nohup xray -c /etc/xray/config.json >/dev/null 2>&1 &
  XRAY_PID=$!
  echo "[+] Xray PID: $XRAY_PID"
}

start_argo() {
  echo "[+] 启动 Cloudflare Argo..."
  if [ -n "$ARGO_TOKEN" ]; then
    nohup cloudflared tunnel run --token "$ARGO_TOKEN" >/tmp/cloudflared.log 2>&1 &
  else
    nohup cloudflared tunnel --url "http://localhost:$XRAY_PORT" --no-autoupdate >/tmp/cloudflared.log 2>&1 &
  fi
  sleep 5
  ARGO_HOST=$(grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared.log | tail -n1 || true)
  if [ -z "$ARGO_HOST" ]; then
    ARGO_HOST="https://未获取域名"
  fi
}

# ================== 输出客户端链接 ==================
print_client_link() {
  local domain="${ARGO_HOST#https://}"
  local ps="vmess-argo"
  client_json=$(cat <<JSON
{
  "v": "2",
  "ps": "$ps",
  "add": "$domain",
  "port": "443",
  "id": "$UUID",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "$domain",
  "path": "$WS_PATH",
  "tls": "tls"
}
JSON
)
  b64=$(echo -n "$client_json" | base64 -w 0)
  echo "====================================================="
  echo "[+] 部署完成"
  echo "[+] UUID: $UUID"
  echo "[+] XRAY_PORT: $XRAY_PORT"
  echo "[+] WS_PATH: $WS_PATH"
  echo "[+] ARGO 域名: $ARGO_HOST"
  echo "[+] 客户端导入链接："
  echo "vmess://$b64"
  echo "====================================================="
}

# ================== 主流程 ==================
main() {
  install_xray
  install_cloudflared
  write_xray_config
  start_xray
  start_argo
  print_client_link
}

main "$@"
