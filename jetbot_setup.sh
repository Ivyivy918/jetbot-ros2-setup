#!/bin/bash

###############################################################################
# JetBot ROS2 Humble 完整環境安裝腳本
# 用途: 在 Jetson Nano/Orin 上一次性安裝所有必要套件
# 作者: Auto-generated setup script
# 日期: 2024
###############################################################################

set -e  # 遇到錯誤立即停止

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日誌函數
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
    log_error "請不要使用 sudo 執行此腳本,腳本會在需要時自動請求權限"
    exit 1
fi

###############################################################################
# 第一部分: 系統更新
###############################################################################
log_info "=========================================="
log_info "第 1 步: 更新系統套件"
log_info "=========================================="
sudo apt update
sudo apt upgrade -y

###############################################################################
# 第二部分: 安裝 ROS2 Humble
###############################################################################
log_info "=========================================="
log_info "第 2 步: 安裝 ROS2 Humble"
log_info "=========================================="

# 檢查是否已安裝 ROS2
if [ -d "/opt/ros/humble" ]; then
    log_warn "ROS2 Humble 已安裝,跳過此步驟"
else
    log_info "安裝 ROS2 Humble 依賴項..."
    sudo apt install -y software-properties-common
    sudo add-apt-repository universe -y
    
    log_info "添加 ROS2 GPG key..."
    sudo apt update && sudo apt install -y curl gnupg lsb-release
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    
    log_info "添加 ROS2 repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    
    log_info "安裝 ROS2 Desktop..."
    sudo apt update
    sudo apt install -y ros-humble-desktop
    
    log_info "ROS2 Humble 安裝完成!"
fi

###############################################################################
# 第三部分: 安裝 ROS2 開發工具
###############################################################################
log_info "=========================================="
log_info "第 3 步: 安裝 ROS2 開發工具"
log_info "=========================================="

sudo apt install -y python3-colcon-common-extensions
sudo apt install -y python3-rosdep

# 初始化 rosdep (如果尚未初始化)
if [ ! -d "/etc/ros/rosdep" ]; then
    log_info "初始化 rosdep..."
    sudo rosdep init
fi

log_info "更新 rosdep..."
rosdep update

###############################################################################
# 第四部分: 安裝 JetBot 硬體驅動
###############################################################################
log_info "=========================================="
log_info "第 4 步: 安裝 JetBot 硬體驅動"
log_info "=========================================="

log_info "安裝 Python 開發工具..."
sudo apt install -y python3-pip python3-dev python3-smbus i2c-tools

log_info "安裝 Adafruit 驅動..."
pip3 install --user Adafruit-MotorHAT
pip3 install --user Adafruit-SSD1306

log_info "設定 I2C 權限..."
sudo usermod -aG i2c $USER
sudo chmod 666 /dev/i2c-* 2>/dev/null || log_warn "I2C 設備未找到,稍後可能需要重啟"

###############################################################################
# 第五部分: 安裝相機與視覺套件
###############################################################################
log_info "=========================================="
log_info "第 5 步: 安裝相機與視覺套件"
log_info "=========================================="

sudo apt install -y \
    ros-humble-cv-bridge \
    ros-humble-vision-opencv \
    ros-humble-image-transport \
    ros-humble-image-transport-plugins \
    ros-humble-camera-calibration \
    ros-humble-stereo-image-proc \
    ros-humble-image-pipeline \
    python3-opencv

###############################################################################
# 第六部分: 安裝 SLAM 套件
###############################################################################
log_info "=========================================="
log_info "第 6 步: 安裝 RTAB-Map SLAM"
log_info "=========================================="

sudo apt install -y ros-humble-rtabmap-ros

###############################################################################
# 第七部分: 安裝機器人描述與 TF 套件
###############################################################################
log_info "=========================================="
log_info "第 7 步: 安裝機器人描述與 TF 套件"
log_info "=========================================="

sudo apt install -y \
    ros-humble-robot-state-publisher \
    ros-humble-joint-state-publisher \
    ros-humble-tf2-ros \
    ros-humble-xacro

###############################################################################
# 第八部分: 安裝系統工具
###############################################################################
log_info "=========================================="
log_info "第 8 步: 安裝系統工具"
log_info "=========================================="

sudo apt install -y \
    git \
    git-lfs \
    curl \
    wget \
    build-essential \
    xterm \
    x11vnc

log_info "設定 Git LFS..."
git lfs install

###############################################################################
# 第九部分: 設定環境變數
###############################################################################
log_info "=========================================="
log_info "第 9 步: 設定環境變數"
log_info "=========================================="

# 備份原始 bashrc
if [ ! -f ~/.bashrc.backup ]; then
    cp ~/.bashrc ~/.bashrc.backup
    log_info "已備份 .bashrc 到 .bashrc.backup"
fi

# 檢查是否已經添加 ROS2 source
if ! grep -q "source /opt/ros/humble/setup.bash" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# ROS2 Humble Environment" >> ~/.bashrc
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
    log_info "已添加 ROS2 環境變數到 .bashrc"
else
    log_warn "ROS2 環境變數已存在於 .bashrc"
fi

# 添加 Python 用戶安裝路徑
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" ~/.bashrc; then
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc
    log_info "已添加 Python 用戶路徑到 .bashrc"
fi

###############################################################################
# 第十部分: 清理與總結
###############################################################################
log_info "=========================================="
log_info "第 10 步: 清理系統"
log_info "=========================================="

sudo apt autoremove -y
sudo apt clean

###############################################################################
# 安裝完成
###############################################################################
echo ""
log_info "=========================================="
log_info "✅ 安裝完成!"
log_info "=========================================="
echo ""
log_info "已安裝的主要套件:"
log_info "  ✓ ROS2 Humble Desktop"
log_info "  ✓ Adafruit MotorHAT & SSD1306"
log_info "  ✓ OpenCV & 相機套件"
log_info "  ✓ RTAB-Map SLAM"
log_info "  ✓ TF2 & Robot State Publisher"
log_info "  ✓ Git LFS & x11vnc"
echo ""
log_warn "⚠️  重要提醒:"
log_warn "  1. 請執行以下指令使環境變數生效:"
log_warn "     source ~/.bashrc"
log_warn "  2. 建議重新啟動系統以確保 I2C 權限生效:"
log_warn "     sudo reboot"
echo ""
log_info "🎉 現在你可以開始使用 JetBot 了!"
echo ""
