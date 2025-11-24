# vmess + Argo 一键脚本 (Linux)

本仓库提供一个 **单文件 Bash 脚本**，可以在 Linux 系统上一键部署：
- Xray (vmess + WebSocket)
- Cloudflare Argo Tunnel (cloudflared)

无需域名和证书，默认使用 Cloudflare Quick Tunnel，自动生成客户端导入链接。

---

## 快速开始

### 下载并运行
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/als168/vmess-argo/main/vmess_argo.sh)"

```
