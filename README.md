# JetBot ROS2 Humble 自動安裝腳本

一鍵安裝 JetBot 開發環境的完整腳本,適用於 Jetson Nano/Orin 平台。

## 📋 功能特色

- ✅ 自動安裝 ROS2 Humble Desktop
- ✅ 配置 Adafruit MotorHAT 和 OLED 驅動
- ✅ 安裝雙目相機與視覺處理套件
- ✅ 配置 RTAB-Map SLAM
- ✅ 設定 TF2 和機器人描述工具
- ✅ 安裝 VNC 遠端桌面
- ✅ 自動配置環境變數和權限

## 🚀 快速開始

### 方法一: 從 GitHub 安裝 (推薦)

```bash
# 1. Clone 這個 repository
git clone https://github.com/<你的用戶名>/jetbot-ros2-setup.git
cd jetbot-ros2-setup

# 2. 執行安裝腳本
chmod +x jetbot_setup.sh
./jetbot_setup.sh

# 3. 重新啟動系統
sudo reboot
```

### 方法二: 直接下載執行

```bash
# 下載腳本
wget https://raw.githubusercontent.com/<你的用戶名>/jetbot-ros2-setup/main/jetbot_setup.sh

# 執行安裝
chmod +x jetbot_setup.sh
./jetbot_setup.sh

# 重新啟動
sudo reboot
```

## 📦 安裝內容

### ROS2 套件
- `ros-humble-desktop` - ROS2 核心套件
- `ros-humble-cv-bridge` - OpenCV 橋接
- `ros-humble-rtabmap-ros` - SLAM 建圖
- `ros-humble-stereo-image-proc` - 雙目影像處理
- `ros-humble-robot-state-publisher` - 機器人狀態發布
- `ros-humble-tf2-ros` - 座標轉換系統
- `ros-humble-xacro` - URDF 巨集處理

### Python 套件
- `Adafruit-MotorHAT` - 馬達控制
- `Adafruit-SSD1306` - OLED 顯示器
- `python3-opencv` - 電腦視覺

### 系統工具
- Git 和 Git LFS
- TigerVNC Server
- Colcon 建構工具
- rosdep 依賴管理

## ⚙️ 系統需求

- **硬體**: Jetson Nano / Jetson Orin Nano
- **作業系統**: Ubuntu 20.04 / 22.04
- **儲存空間**: 至少 10GB 可用空間
- **網路**: 需要網際網路連線

## 📝 使用說明

### 安裝後驗證

```bash
# 檢查 ROS2 環境
source ~/.bashrc
ros2 --version

# 檢查已安裝的套件
ros2 pkg list | grep rtabmap
ros2 pkg list | grep stereo

# 測試 I2C 設備
i2cdetect -y -r 1
```

### 常見問題

**Q: 腳本執行到一半停止了?**  
A: 檢查網路連線,然後重新執行腳本。腳本會跳過已安裝的部分。

**Q: I2C 權限問題?**  
A: 重新啟動系統後權限會生效:`sudo reboot`

**Q: ROS2 指令找不到?**  
A: 執行 `source ~/.bashrc` 或重新開啟終端機。

**Q: 想要重新安裝?**  
A: 可以直接重新執行腳本,已安裝的套件會被跳過。

## 🔧 自訂安裝

如果你只需要部分功能,可以編輯 `jetbot_setup.sh` 並註解掉不需要的部分:

```bash
# 例如:不需要 VNC,可以註解這幾行
# sudo apt install -y \
#     tigervnc-standalone-server \
#     tigervnc-common
```

## 📂 檔案結構

```
jetbot-ros2-setup/
├── jetbot_setup.sh    # 主要安裝腳本
├── README.md          # 本說明文件
└── LICENSE            # 授權文件 (可選)
```

## 🤝 貢獻

歡迎提交 Issue 或 Pull Request!

## 📄 授權

MIT License - 自由使用和修改

## 🎯 下一步

安裝完成後,你可以:

1. **設定你的 JetBot workspace**
   ```bash
   mkdir -p ~/ros2_ws/src
   cd ~/ros2_ws
   colcon build
   ```

2. **測試相機**
   ```bash
   ros2 run image_tools cam2image
   ```

3. **啟動 SLAM**
   ```bash
   ros2 launch rtabmap_ros rtabmap.launch.py
   ```

4. **開發你的機器人應用!** 🤖

## 📞 聯絡方式

如有問題請開 Issue 或聯絡: [你的聯絡方式]

---

⭐ 如果這個腳本對你有幫助,請給個星星!
