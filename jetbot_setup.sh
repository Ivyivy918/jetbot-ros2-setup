#!/bin/bash

###############################################################################
# JetBot ROS2 Humble 終極重生腳本 (Orin Nano 優化版)
# 用途: 針對 JetPack 6 + ROS2 Humble 進行驅動鎖定與環境優化
###############################################################################

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -eq 0 ]; then 
    log_error "請不要使用 sudo 執行此腳本"
    exit 1
fi

###############################################################################
# 第一部分: 驅動保護與系統更新
###############################################################################
log_info "第 1 步: 鎖定 Jetson 原生驅動並更新系統"

# 🛑 [關鍵修正] 防止抓到 PC 版 (590.44) 驅動導致 SD 卡毀損
log_warn "正在鎖定 L4T 原生驅動以防止版本衝突..."
sudo apt-mark hold nvidia-l4t-core nvidia-l4t-camera nvidia-l4t-multimedia nvidia-l4t-3d-core || true

sudo apt update
sudo apt upgrade -y

###############################################################################
# 第二、三部分: ROS2 Humble & 工具
###############################################################################
log_info "第 2-3 步: 安裝 ROS2 Humble 與開發工具"

if [ ! -d "/opt/ros/humble" ]; then
    sudo apt install -y software-properties-common
    sudo add-apt-repository universe -y
    sudo apt update && sudo apt install -y curl gnupg lsb-release
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    sudo apt update
    sudo apt install -y ros-humble-desktop
fi

sudo apt install -y python3-colcon-common-extensions python3-rosdep python3-pip python3-dev
[ ! -d "/etc/ros/rosdep" ] && sudo rosdep init || true
rosdep update

###############################################################################
# 第四部分: Feather 馬達驅動與 I2C 權限
###############################################################################
log_info "第 4 步: 設定 Feather 馬達驅動與硬體權限"

# Feather 驅動器通常走 USB/Serial，必須加入 dialout 群組
sudo usermod -aG dialout $USER
sudo usermod -aG i2c $USER
sudo apt install -y i2c-tools python3-smbus

# 安裝基本馬達控制庫
pip3 install --user Adafruit-MotorHAT Adafruit-SSD1306

###############################################################################
# 第五、七部分: 視覺、TF、與無頭模式工具
###############################################################################
log_info "第 5-7 步: 安裝視覺與深度計算套件"

# 🛑 [重要] 移除 python3-opencv 避免覆蓋 JetPack 優化版
# 安裝 ROS2 視覺橋接與必要工具
sudo apt install -y \
    ros-humble-cv-bridge \
    ros-humble-vision-opencv \
    ros-humble-image-transport \
    ros-humble-image-transport-plugins \
    ros-humble-robot-state-publisher \
    ros-humble-xacro \
    ros-humble-tf2-ros \
    xvfb  # 昨晚救命用的虛擬螢幕

###############################################################################
# 第九部分: 環境變數設定 (無頭模式優化)
###############################################################################
log_info "第 9 步: 設定自動化環境變數"

BASHRC=~/.bashrc
# 加入 ROS2 Source
grep -q "source /opt/ros/humble/setup.bash" $BASHRC || echo "source /opt/ros/humble/setup.bash" >> $BASHRC

# 🛑 [自動化設定] 解決 EGL Display 報錯
grep -q "export DISPLAY=:0" $BASHRC || echo "export DISPLAY=:0" >> $BASHRC
grep -q "export XAUTHORITY" $BASHRC || echo "export XAUTHORITY=/home/$USER/.Xauthority" >> $BASHRC

# 🛑 [網路設定] 防止跨網卡通訊失敗
grep -q "export ROS_LOCALHOST_ONLY=0" $BASHRC || echo "export ROS_LOCALHOST_ONLY=0" >> $BASHRC

log_info "✅ 環境變數設定完成"

###############################################################################
# 結尾
###############################################################################
sudo apt autoremove -y && sudo apt clean
log_info "=========================================="
log_info "🎉 重生完成！姿佑，小車已經準備好睜開雙眼了。"
log_info "=========================================="
log_warn "請執行: source ~/.bashrc 或是直接 sudo reboot"