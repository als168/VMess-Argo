# Xray + Argo 极简一键管理脚本

本脚本适合低配 VPS（128MB 内存 / 256MB 存储），支持两种隧道模式：
- **临时隧道 (Quick Tunnel)** —— 简单快速，但域名随机、不稳定
- **自建隧道 (命名隧道/有 token)** —— 需要 Cloudflare 账号，域名固定，稳定性高

脚本名称：`vmess_argo.sh`

---

## 一键运行命令

无需下载，直接运行：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/als168/vmess-argo/main/vmess_argo.sh)"
```
---
功能菜单
---
运行后会出现菜单：

```
===== Xray + Argo 管理 =====
1. 安装并启动 (生成一键链接)
2. 卸载
0. 退出
```
输入 1 → 安装并启动，生成完整的 vmess:// 导入链接

输入 2 → 卸载，清理所有文件和进程

输入 0 → 退出脚本


---
运行后选择：
```
请选择隧道模式：
1. 临时隧道 (Quick Tunnel) —— 简单快速，但域名随机、不稳定
2. 自建隧道 (需要 Cloudflare 账号和 token) —— 域名固定，稳定性高
```
输入 1 → 使用临时隧道，自动生成一个随机域名。

输入 2 → 使用自建隧道，需要输入你在 Cloudflare 面板里创建的 token。

---

许可证
---
MIT License
```
---

### `vmess_argo_min.sh`

就是我之前帮你写的 **精简版脚本（带选择提示）**，你只要复制进去即可。

---

✅ 这样你就有一个完整的仓库结构：  
- `README.md` 让人一眼就能看懂临时隧道和自建隧道的区别。  
- `vmess_argo_min.sh` 是极简脚本，适合低配 VPS。  

要不要我帮你直接写好 **GitHub 上传步骤**（从本地 VPS 到 GitHub 仓库），让你一步步照着操作？
```
