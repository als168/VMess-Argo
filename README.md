# VMess + Argo 一键部署脚本
 

本仓库提供一个一键脚本，快速部署 **Xray (VMess)** + **Cloudflare Argo 隧道**。  
支持 **临时隧道 (Quick Tunnel)** 和 **自建隧道 (Named Tunnel)** 两种模式。


---

## 功能特点
- ✅ 自动安装 Xray 与 Cloudflared
- ✅ 自动生成配置文件，无需手动修改
- ✅ 支持临时隧道（无需 Cloudflare 控制台）
- ✅ 支持自建隧道（绑定自己的域名）
- ✅ 自动输出 V2RayN 链接，复制即可导入客户端
- ✅ 一键卸载，环境干净

---

## 使用方法

### 1. 下载并运行脚本
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<你的仓库>/main/vmess_argo.sh)
```
2. 选择模式
 ```
``` 
运行后会出现菜单：
```
===== VMess + Argo =====
1. 安装并启动 (临时隧道)
2. 安装并启动 (自建隧道)
3. 卸载
0. 退出
```
