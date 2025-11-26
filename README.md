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

使用方法

1. 下载并运行脚本
---
 xray：
---
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/als168/vmess-argo/main/vmess_argo.sh)
```
sing-box：
---
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/als168/vmess-argo/main/sb_argo.sh)
```
2. 选择模式
---
运行后会出现菜单：

===== VMess + Argo =====
1. 安装并启动 (临时隧道)
2. 安装并启动 (自建隧道)
3. 卸载
0. 退出
---
选 1 → 临时隧道，自动生成 trycloudflare.com 域名

选 2 → 自建隧道，需要输入：

隧道 ID

域名（你在 Cloudflare 控制台绑定的域名）

Argo 隧道 token

---

---
Cloudflare 推荐 Zero Trust 面板:
---

第一步：进入 Zero Trust 面板

登录你的 Cloudflare 官网。

在左侧菜单栏找到 Zero Trust 图标，点击进入。

如果是第一次进入，它可能会让你选个 Plan，选 Free (免费版) 即可。可能需要绑定支付方式（Paypal/信用卡），但不会扣费。

第二步：创建隧道 (Create Tunnel)

在 Zero Trust 面板左侧菜单，点击 Networks -> Tunnels。

点击页面中间蓝色的 Create a tunnel 按钮。

Select connector（选择连接器）：保持默认的 Cloudflared，点击 Next。

Name your tunnel（给隧道起名）：随便填，比如 vps-hk，点击 Save tunnel。

第三步：获取 Token (关键步骤)

你会看到一个页面，上面有一堆安装命令（Install and run a connector）。

看那个方框里的代码。

找到 --token 后面的那串 长长的字符串（以 ey 开头，非常长）。

这就是 Token！ 把它复制出来保存好。

注意：不要复制整行命令，脚本只要那个 Token 字符串。

点击下方的 Next 继续。

第四步：设置公网访问 (Public Hostname)

这一步是告诉 Cloudflare：当别人访问你的域名时，把流量转发给 VPS 里的哪个端口。

点击 Public Hostnames 标签页。

点击 Add a public hostname。

填写信息（配合刚才的脚本）：

Subdomain (子域名): 填你想用的前缀，例如 vps。

Domain (域名): 下拉选择你已经绑定在 Cloudflare 的域名。

(比如你填了 vps，选了 abc.com，那你的节点地址就是 vps.abc.com)

Path: 留空，不要填。

Service (服务配置 - 最重要的一步)：

Type: 选择 HTTP (注意不是 HTTPS)。

URL: 填写 localhost:8001。

解释：因为刚才的脚本里，Sing-box 就监听在 VPS 内部的 8001 端口。

点击右下角的 Save hostname。

第五步：回到 VPS 运行脚本

现在你有了 Token，也设置好了 Hostname。

选择 1. 固定隧道。

脚本问你要 Token 时，粘贴 第三步 获取的那串 ey...。

脚本问你要域名时，输入 第四步 设置的完整域名（如 vps.abc.com）。

🎉 完成！

状态确认：回到 Cloudflare 的 Tunnels 列表页面，你会看到你的隧道状态（Status）变成了绿色的 Healthy（健康）。

客户端连接：在 v2rayN 里，地址填 vps.abc.com，端口 443，就能连上了！

---
注意事项
---
临时隧道：域名为 xxxx.trycloudflare.com，适合测试。

自建隧道：必须在 Cloudflare 控制台创建隧道并绑定域名。

端口固定：Xray 默认监听在 8001，Cloudflared 配置已自动指向该端口。

路径固定：WebSocket 路径为 /vmess。

TLS 必须开启：客户端配置时一定要勾选 TLS。

常见问题
---
延迟显示 -1 → 检查客户端配置是否和服务端一致（域名、端口、UUID、路径、TLS、Host）。

502 错误 → 通常是 Cloudflared 配置不正确或 Xray 没启动。

域名解析失败 → 等待 DNS 缓存刷新，或直接用 ping 域名 测试。

致谢
---
Xray-core

Cloudflared

sing-box
