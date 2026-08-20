# LagDaemon 🧠💾

  > 猫娘版喵 —— 内存固定占用 + CPU 持续计算圆周率（结果保存）

  **LagDaemon** 是一个用于“修复系统太流畅”的娱乐/测试工具。它通过：
  - 使用 `tmpfs` + `dd` 固定占用系统内存（默认总内存 40%，至少 1GB）
  - 使用 `bc -l` 多核心持续计算圆周率（5000~15000 位），并将结果保存至 `/tmp/pi_results/`

  **服务化**：集成 systemd，开机自启，一键停止/卸载（不要喵～）。
  **食用方法**：
  - 运行安装脚本： chmod + x install-lagdaemon.sh && sudo bash ./install-lagdaemon.sh
  - 卸载：sudo bash ./install-lagdaemon.sh uninstall

**联系**：
  - lizy_0704@outlook.com
  - bilibili:_星辰旅人_
