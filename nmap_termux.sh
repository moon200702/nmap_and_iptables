#!/data/data/com.termux/files/usr/bin/bash

# 🔧 1. 使用 termux-dialog 收集輸入
get_input() {
    local label="$1"
    local varname="$2"
    local result
    result=$(termux-dialog -t "$label" | jq -r .text)
    eval "$varname=\"$result\""
}

get_input "請輸入要檢查的 IP" IP
get_input "請輸入子網掩碼 (如 255.255.255.0)" NETMASK
get_input "請輸入閘道 (Gateway)" GATEWAY
get_input "請輸入 DNS (可空白)" DNS
get_input "請輸入網卡名稱 (如 Ethernet)" INTERFACE

termux-toast "正在掃描 $IP..."

# 🔍 2. 掃描 IP 是否有服務活著
NMAP_RESULT=$(nmap -Pn $IP)

if echo "$NMAP_RESULT" | grep -A 10 "^PORT" | grep -q "open"; then
    termux-toast "❌ $IP 有開放埠，已被使用"
    echo "$NMAP_RESULT" | grep -A 10 "^PORT"
    exit 1
fi

termux-toast "✅ $IP 看起來可用"

# 🧮 3. 計算 CIDR
mask2cidr() {
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
CIDR=$(mask2cidr "$NETMASK")

# 🖥️ 4. 組合 CMD 與 PowerShell 指令
CMD="netsh interface ip set address name=\"$INTERFACE\" static $IP $NETMASK $GATEWAY"
[ -n "$DNS" ] && CMD+="\nnetsh interface ip set dns name=\"$INTERFACE\" static $DNS"

PS="\$i = Get-NetAdapter -Name \"$INTERFACE\"\n"
PS+="New-NetIPAddress -InterfaceAlias \$i.Name -IPAddress $IP -PrefixLength $CIDR -DefaultGateway $GATEWAY"
[ -n "$DNS" ] && PS+="\nSet-DnsClientServerAddress -InterfaceAlias \$i.Name -ServerAddresses $DNS"

# 📋 5. 複製到剪貼簿
FULL_OUTPUT="【CMD 指令】\n$CMD\n\n【PowerShell 指令】\n$PS"
echo -e "$FULL_OUTPUT" | termux-clipboard-set
termux-toast "已複製 CMD/PS 指令到剪貼簿！"

# 🖨️ 6. 輸出到畫面
echo -e "$FULL_OUTPUT"
