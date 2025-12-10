#!/bin/bash

###############################################################################
# x11vnc 自動設定腳本
# 功能: 設定密碼、建立 systemd service、設定開機自動啟動
###############################################################################

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查是否為 root
if [ "$EUID" -eq 0 ]; then
    log_error "請不要使用 sudo 執行此腳本"
    exit 1
fi

# 獲取當前用戶名
CURRENT_USER=$(whoami)

log_info "=========================================="
log_info "x11vnc 自動設定開始"
log_info "=========================================="

###############################################################################
# Step 1: 檢查 x11vnc 是否已安裝
###############################################################################
log_info "檢查 x11vnc 是否已安裝..."
if ! command -v x11vnc &> /dev/null; then
    log_error "x11vnc 未安裝,請先執行 jetbot_setup.sh"
    exit 1
fi
log_info "✓ x11vnc 已安裝"

###############################################################################
# Step 2: 創建 .vnc 目錄
###############################################################################
log_info "創建 VNC 設定目錄..."
mkdir -p ~/.vnc
chmod 700 ~/.vnc

###############################################################################
# Step 3: 設定 VNC 密碼
###############################################################################
log_info "設定 VNC 密碼..."

# 使用預設密碼 A910626
VNC_PASSWORD="A910626"

# 使用 expect 自動輸入密碼 (如果沒有 expect 就安裝)
if ! command -v expect &> /dev/null; then
    log_info "安裝 expect 工具..."
    sudo apt install -y expect
fi

# 創建臨時 expect 腳本
cat > /tmp/set_vnc_passwd.exp << EOF
#!/usr/bin/expect -f
set timeout 10
spawn x11vnc -storepasswd
expect "Enter VNC password:"
send "$VNC_PASSWORD\r"
expect "Verify password:"
send "$VNC_PASSWORD\r"
expect eof
EOF

chmod +x /tmp/set_vnc_passwd.exp
/tmp/set_vnc_passwd.exp
rm /tmp/set_vnc_passwd.exp

log_info "✓ VNC 密碼已設定為: $VNC_PASSWORD"

###############################################################################
# Step 4: 創建虛擬顯示器設定 (解決無頭模式問題)
###############################################################################
log_info "設定虛擬顯示器 (解決無螢幕問題)..."

# 安裝 xvfb (虛擬幀緩衝)
sudo apt install -y xvfb

# 創建 X11 虛擬顯示器的 systemd service
sudo tee /etc/systemd/system/xvfb.service > /dev/null << EOF
[Unit]
Description=Virtual Frame Buffer X Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :0 -screen 0 1920x1080x24
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

log_info "✓ 虛擬顯示器設定完成"

###############################################################################
# Step 5: 創建 x11vnc systemd service
###############################################################################
log_info "創建 x11vnc systemd service..."

sudo tee /etc/systemd/system/x11vnc.service > /dev/null << EOF
[Unit]
Description=x11vnc VNC Server
After=xvfb.service
Requires=xvfb.service

[Service]
Type=simple
Environment="DISPLAY=:0"
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/x11vnc \\
    -display :0 \\
    -auth guess \\
    -forever \\
    -loop \\
    -noxdamage \\
    -repeat \\
    -rfbauth /home/${CURRENT_USER}/.vnc/passwd \\
    -rfbport 5900 \\
    -shared \\
    -o /var/log/x11vnc.log
User=${CURRENT_USER}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

log_info "✓ systemd service 已創建"

###############################################################################
# Step 6: 啟用並啟動服務
###############################################################################
log_info "啟用服務..."

# 重新載入 systemd
sudo systemctl daemon-reload

# 啟用 xvfb (虛擬顯示器)
sudo systemctl enable xvfb.service
sudo systemctl start xvfb.service

# 啟用 x11vnc
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

log_info "✓ 服務已啟動"

###############################################################################
# Step 7: 檢查服務狀態
###############################################################################
log_info "檢查服務狀態..."

sleep 3

if systemctl is-active --quiet xvfb.service; then
    log_info "✓ Xvfb (虛擬顯示器) 運行中"
else
    log_warn "⚠ Xvfb 未正常運行"
fi

if systemctl is-active --quiet x11vnc.service; then
    log_info "✓ x11vnc 運行中"
else
    log_warn "⚠ x11vnc 未正常運行"
fi

###############################################################################
# Step 8: 創建快捷管理腳本
###############################################################################
log_info "創建管理腳本..."

cat > ~/vnc_control.sh << 'EOF'
#!/bin/bash
# x11vnc 快速控制腳本

case "$1" in
    start)
        sudo systemctl start xvfb.service
        sudo systemctl start x11vnc.service
        echo "✓ VNC 已啟動"
        ;;
    stop)
        sudo systemctl stop x11vnc.service
        sudo systemctl stop xvfb.service
        echo "✓ VNC 已停止"
        ;;
    restart)
        sudo systemctl restart xvfb.service
        sudo systemctl restart x11vnc.service
        echo "✓ VNC 已重啟"
        ;;
    status)
        echo "=== Xvfb 狀態 ==="
        systemctl status xvfb.service --no-pager
        echo ""
        echo "=== x11vnc 狀態 ==="
        systemctl status x11vnc.service --no-pager
        ;;
    log)
        echo "=== x11vnc 日誌 ==="
        sudo tail -50 /var/log/x11vnc.log
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|log}"
        exit 1
        ;;
esac
EOF

chmod +x ~/vnc_control.sh

log_info "✓ 管理腳本已創建: ~/vnc_control.sh"

###############################################################################
# Step 9: 設定防火牆 (如果有啟用 ufw)
###############################################################################
if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    log_info "設定防火牆規則..."
    sudo ufw allow 5900/tcp
    log_info "✓ 防火牆已允許 VNC 連線 (port 5900)"
fi

###############################################################################
# 完成
###############################################################################
echo ""
log_info "=========================================="
log_info "✅ x11vnc 設定完成!"
log_info "=========================================="
echo ""
log_info "連線資訊:"
log_info "  VNC 密碼: A910626"
log_info "  VNC 埠號: 5900"
log_info "  連線方式: <JetBot的IP>:5900"
echo ""
log_info "管理指令:"
log_info "  啟動 VNC:   ~/vnc_control.sh start"
log_info "  停止 VNC:   ~/vnc_control.sh stop"
log_info "  重啟 VNC:   ~/vnc_control.sh restart"
log_info "  查看狀態:   ~/vnc_control.sh status"
log_info "  查看日誌:   ~/vnc_control.sh log"
echo ""
log_info "systemctl 指令:"
log_info "  查看狀態:   sudo systemctl status x11vnc"
log_info "  查看日誌:   sudo journalctl -u x11vnc -f"
echo ""
log_warn "⚠️ 重要提醒:"
log_warn "  1. VNC 已設定為開機自動啟動"
log_warn "  2. 即使沒有外接螢幕也可以使用 (虛擬顯示器)"
log_warn "  3. 預設解析度為 1920x1080"
log_warn "  4. VNC 密碼為固定值,建議只在區域網路使用"
echo ""
log_info "🎉 現在可以用 VNC Viewer 連線了!"
echo ""
