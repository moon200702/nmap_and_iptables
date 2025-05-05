# 📡 IP Config Tool for Termux Widget

這是一個針對 Android 手機 + Termux 使用者設計的小工具，用於：
- 掃描指定 IP 是否已被使用（透過 `nmap -Pn`）
- 若 IP 可用，自動產出 Windows 的靜態 IP 設定指令（CMD 與 PowerShell）
- 一鍵複製指令到剪貼簿
- 可透過桌面 Widget 一鍵執行！

> 🛠 適合在醫院、實驗室或需手動設定靜態 IP 的環境快速使用。

---

## 🧰 安裝需求

請在 Termux 中安裝下列工具：

```bash
pkg update
pkg install nmap termux-api jq


ip-config-tool-termux/
├── README.md
├── check_ip_termux.sh         <-- 主程式
├── LICENSE                    <-- 授權條款（可選 MIT）
└── screenshots/               <-- 截圖資料夾（可選）
