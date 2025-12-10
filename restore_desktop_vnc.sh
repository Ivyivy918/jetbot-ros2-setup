#!/bin/bash

###############################################################################
# 恢復原本桌面並設定 VNC 分享
# 功能: 讓 VNC 分享你實際使用的桌面,拔掉 HDMI 後仍可存取
###############################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

CURRENT_USER=$(whoami)

log_info "=========================================="
log_info "恢復原本桌面 + 設定 VNC 分享"
log_info "=========================================="

###############################################################################
# Step 1: 停止並移除虛擬顯示器服務
###############################################################################
log_info "Step 1: 停止並移除虛擬顯示器服務..."

sudo systemctl stop x11vnc 2>/dev/null || true
sudo systemctl stop gnome-headless 2>/dev/null || true
sudo systemctl stop xvfb 2>/dev/null || true

sudo systemctl disable x11vnc 2>/dev/null || true
sudo systemctl disable gnome-headless 2>/dev/null || true
sudo systemctl disable xvfb 2>/dev/null || true

# 刪除虛擬顯示器相關服務
sudo rm -f /etc/systemd/system/xvfb.service
sudo rm -f /etc/systemd/system/gnome-headless.service

pkill -9 Xvfb 2>/dev/null || true
pkill -9 x11vnc 2>/dev/null || true

sleep 2
log_info "✓ 已清除虛擬顯示器服務"

###############################################################################
# Step 2: 恢復原本的 GNOME 桌面
###############################################################################
log_info "Step 2: 恢復原本的 GNOME 桌面..."

# 重啟顯示管理器
sudo systemctl restart gdm3 2>/dev/null || sudo systemctl restart lightdm 2>/dev/null || true
sleep 3

log_info "✓ 桌面管理器已重啟"

###############################################################################
# Step 3: 確保 GNOME 在無頭模式下也能啟動
###############################################################################
log_info "Step 3: 設定 GNOME 無頭模式..."

# 創建配置讓 GNOME 在沒有實體螢幕時也啟動
sudo mkdir -p /etc/X11/xorg.conf.d/

sudo tee /etc/X11/xorg.conf.d/10-headless.conf > /dev/null << 'EOF'
Section "Monitor"
    Identifier "Dummy"
    HorizSync 28.0-80.0
    VertRefresh 48.0-75.0
    Modeline "1920x1080" 148.50 1920 2448 2492 2640 1080 1084 1089 1125 +Hsync +Vsync
EndSection

Section "Device"
    Identifier "Dummy"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Screen"
    Identifier "Dummy"
    Device "Dummy"
    Monitor "Dummy"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
EOF

log_info "✓ 無頭模式設定完成"

###############################################################################
# Step 4: 安裝 dummy 顯示驅動
###############################################################################
log_info "Step 4: 安裝 dummy 顯示驅動..."
sudo apt update
sudo apt install -y xserver-xorg-video-dummy

log_info "✓ Dummy 驅動已安裝"

###############################################################################
# Step 5: 修正 VNC 日誌權限
###############################################################################
log_info "Step 5: 修正 VNC 日誌權限..."
sudo touch /var/log/x11vnc.log
sudo chown $CURRENT_USER:$CURRENT_USER /var/log/x11vnc.log
sudo chmod 644 /var/log/x11vnc.log

###############################################################################
# Step 6: 創建新的 x11vnc service (分享實際桌面)
###############################################################################
log_info "Step 6: 創建 x11vnc service (分享實際桌面)..."

sudo tee /etc/systemd/system/x11vnc.service > /dev/null << EOF
[Unit]
Description=x11vnc VNC Server - Share Real Desktop
After=display-manager.service
Requires=display-manager.service

[Service]
Type=simple
User=${CURRENT_USER}
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/run/user/$(id -u ${CURRENT_USER})/gdm/Xauthority"
ExecStartPre=/bin/sleep 5
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
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

log_info "✓ x11vnc service 已創建"

###############################################################################
# Step 7: 重新載入並啟動服務
###############################################################################
log_info "Step 7: 啟用 x11vnc service..."

sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

sleep 3

###############################################################################
# Step 8: 檢查狀態
###############################################################################
log_info "=========================================="
log_info "檢查狀態"
log_info "=========================================="

echo ""
if systemctl is-active --quiet x11vnc.service; then
    log_info "✓ x11vnc 運行中"
else
    log_error "✗ x11vnc 未正常運行"
fi

echo ""
VNC_PORT=$(sudo netstat -tulpn 2>/dev/null | grep 5900)
if [ -n "$VNC_PORT" ]; then
    log_info "✓ VNC 正在監聽 port 5900"
    echo "$VNC_PORT"
else
    log_error "✗ VNC 未監聽 port 5900"
fi

echo ""
log_info "=========================================="
log_info "設定完成"
log_info "=========================================="
echo ""
log_info "現在的設定:"
log_info "  ✓ VNC 會分享你實際的 GNOME 桌面"
log_info "  ✓ 插著 HDMI: 螢幕和 VNC 看到相同畫面"
log_info "  ✓ 拔掉 HDMI: VNC 仍可看到完整桌面"
echo ""
log_info "連線資訊:"
log_info "  IP: $(hostname -I | awk '{print $1}')"
log_info "  埠號: 5900"
log_info "  密碼: A910626"
echo ""
log_warn "⚠️  重要: 請重新開機以確保所有設定生效"
log_warn "執行: sudo reboot"
echo ""
