#!/bin/bash

read -p "請輸入你要檢查的 IP 位址: " IP
read -p "請輸入子網掩碼 (例如 255.255.255.0): " NETMASK
read -p "請輸入閘道 IP: " GATEWAY
read -p "請輸入 DNS (可空白): " DNS
read -p "請輸入網卡名稱 (例如 Ethernet 或 Wi-Fi): " INTERFACE

echo "🔍 使用 nmap -Pn 掃描常見埠以確認 $IP 是否已被使用..."

# 掃描 IP 常見埠，確認是否有任何開放的服務
NMAP_RESULT=$(nmap -Pn $IP)

if echo "$NMAP_RESULT" | grep -A 10 "^PORT" | grep -q "open"; then
    echo "❌ $IP 有開放的服務埠，可能已被使用"
    echo "---- Nmap 掃描結果 ----"
    echo "$NMAP_RESULT" | grep -A 10 "^PORT"
    exit 1
fi

echo "✅ $IP 看起來是可用的，以下是設定指令："

# 轉換成 CIDR
function mask2cidr() {
    local x=${1//./ }
    local count=0
    for i in $x; do
        while [ $i -gt 0 ]; do
            ((count += i % 2))
            i=$((i >> 1))
        done
    done
    echo $count
}

CIDR=$(mask2cidr $NETMASK)

# Windows CMD 指令
echo
echo "📋 CMD 指令："
echo "netsh interface ip set address name=\"$INTERFACE\" static $IP $NETMASK $GATEWAY"
[ -n "$DNS" ] && echo "netsh interface ip set dns name=\"$INTERFACE\" static $DNS"

# PowerShell 指令
echo
echo "📋 PowerShell 指令："
echo "\$interface = Get-NetAdapter -Name \"$INTERFACE\""
echo "New-NetIPAddress -InterfaceAlias \"\$interface.Name\" -IPAddress $IP -PrefixLength $CIDR -DefaultGateway $GATEWAY"
[ -n "$DNS" ] && echo "Set-DnsClientServerAddress -InterfaceAlias \"\$interface.Name\" -ServerAddresses $DNS"

echo
echo "⚠️ 請確認網卡名稱正確，建議使用：Get-NetAdapter 查看現有網卡"
