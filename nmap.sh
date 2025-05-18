#!/bin/bash

read -p "請輸入你要檢查的 IP 位址: " IP
read -p "請輸入子網掩碼 (可填 255.255.255.0 或 /24): " MASK
read -p "請輸入閘道 IP: " GATEWAY
read -p "請輸入 DNS (可空白): " DNS
read -p "請輸入網卡名稱 (例如 Ethernet 或 Wi-Fi): " INTERFACE

# ▓▓▓ 判斷 Netmask 或 CIDR 格式 ▓▓▓
if [[ "$MASK" =~ ^/[0-9]{1,2}$ ]]; then
    CIDR="${MASK#/}"
    function cidr2mask() {
        local i mask=""
        local full_octets=$((CIDR / 8))
        local remaining_bits=$((CIDR % 8))
        for ((i = 0; i < 4; i++)); do
            if ((i < full_octets)); then
                mask+=255
            elif ((i == full_octets)); then
                mask+=$((256 - 2 ** (8 - remaining_bits)))
            else
                mask+=0
            fi
            [[ $i -lt 3 ]] && mask+=.
        done
        echo $mask
    }
    NETMASK=$(cidr2mask)
else
    NETMASK="$MASK"
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
fi

# ▓▓▓ 檢查 IP 使用狀況 ▓▓▓
echo "🔍 使用 nmap -Pn 掃描常見埠以確認 $IP 是否已被使用..."
NMAP_RESULT=$(nmap -Pn $IP)

if echo "$NMAP_RESULT" | grep -A 10 "^PORT" | grep -q "open"; then
    echo "❌ $IP 有開放的服務埠，可能已被使用"
    echo "---- Nmap 掃描結果 ----"
    echo "$NMAP_RESULT" | grep -A 10 "^PORT"
    exit 1
fi

echo "✅ $IP 看起來是可用的，以下是設定指令："

# ▓▓▓ CMD 與 PowerShell 指令 ▓▓▓
echo
echo "📋 CMD 指令："
echo "netsh interface ip set address name=\"$INTERFACE\" static $IP $NETMASK $GATEWAY"
[ -n "$DNS" ] && echo "netsh interface ip set dns name=\"$INTERFACE\" static $DNS"

echo
echo "📋 PowerShell 指令："
echo "\$interface = Get-NetAdapter -Name \"$INTERFACE\""
echo "New-NetIPAddress -InterfaceAlias \"\$interface.Name\" -IPAddress $IP -PrefixLength $CIDR -DefaultGateway $GATEWAY"
[ -n "$DNS" ] && echo "Set-DnsClientServerAddress -InterfaceAlias \"\$interface.Name\" -ServerAddresses $DNS"

echo
echo "⚠️ 請確認網卡名稱正確，建議使用：Get-NetAdapter 查看現有網卡"

