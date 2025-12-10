# x11vnc 設定與使用指南

x11vnc 允許你遠端連線到 JetBot 的實際桌面會話,比 TigerVNC 更方便直接。

## 🔧 基本設定

### 1. 設定 VNC 密碼 (首次使用)

```bash
# 創建密碼檔案
x11vnc -storepasswd
# 會提示你輸入密碼,密碼會儲存在 ~/.vnc/passwd
```

### 2. 啟動 x11vnc

```bash
# 基本啟動 (臨時使用)
x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd -rfbport 5900 -shared
```

### 3. 設定開機自動啟動 (推薦)

創建 systemd service:

```bash
# 創建 service 檔案
sudo nano /etc/systemd/system/x11vnc.service
```

貼上以下內容:

```ini
[Unit]
Description=Start x11vnc at startup
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/jetbot/.vnc/passwd -rfbport 5900 -shared -bg -o /var/log/x11vnc.log
User=jetbot
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**注意**: 將 `jetbot` 改成你的實際用戶名!

啟用 service:

```bash
# 重新載入 systemd
sudo systemctl daemon-reload

# 啟用開機自動啟動
sudo systemctl enable x11vnc.service

# 立即啟動
sudo systemctl start x11vnc.service

# 檢查狀態
sudo systemctl status x11vnc.service
```

## 🖥️ 從電腦連線到 JetBot

### Windows

1. 下載 VNC Viewer: https://www.realvnc.com/en/connect/download/viewer/
2. 安裝後開啟
3. 輸入連線位址: `<JetBot的IP>:5900`
4. 輸入你設定的密碼

### macOS

1. 內建就有 VNC 客戶端
2. 打開 Finder
3. 按 `Cmd + K`
4. 輸入: `vnc://<JetBot的IP>:5900`
5. 輸入密碼

### Linux

```bash
# 使用 Remmina (推薦)
sudo apt install remmina
remmina

# 或使用 vncviewer
sudo apt install tigervnc-viewer
vncviewer <JetBot的IP>:5900
```

## 📋 常用指令

```bash
# 啟動 x11vnc (前景模式,用於測試)
x11vnc -display :0 -auth guess

# 啟動 x11vnc (背景模式)
x11vnc -display :0 -auth guess -forever -bg

# 檢查 x11vnc 是否在執行
ps aux | grep x11vnc

# 停止 x11vnc
pkill x11vnc

# 使用 systemd 控制 (如果已設定 service)
sudo systemctl start x11vnc    # 啟動
sudo systemctl stop x11vnc     # 停止
sudo systemctl restart x11vnc  # 重啟
sudo systemctl status x11vnc   # 查看狀態
```

## ⚙️ 指令參數說明

- `-display :0` - 使用主顯示器
- `-auth guess` - 自動猜測認證檔案位置
- `-forever` - 持續執行,不會在客戶端斷線後關閉
- `-loop` - 如果伺服器關閉,自動重啟
- `-noxdamage` - 不使用 XDAMAGE 擴展 (某些系統需要)
- `-repeat` - 允許按鍵重複
- `-rfbauth ~/.vnc/passwd` - 使用密碼檔案
- `-rfbport 5900` - 監聽 5900 埠 (VNC 預設)
- `-shared` - 允許多個客戶端同時連線
- `-bg` - 背景執行
- `-o /var/log/x11vnc.log` - 日誌檔案位置

## 🔒 安全性建議

### 1. 只在區域網路使用

VNC 預設沒有加密,建議只在信任的區域網路使用。

### 2. 使用 SSH 隧道 (推薦)

如果需要透過網際網路連線:

```bash
# 在你的電腦上執行
ssh -L 5900:localhost:5900 jetbot@<JetBot的IP>

# 然後用 VNC Viewer 連線到 localhost:5900
```

### 3. 修改預設埠

```bash
# 使用不同的埠 (例如 5901)
x11vnc -display :0 -auth guess -rfbport 5901 ...
```

### 4. 限制連線 IP

```bash
# 只允許特定 IP 連線
x11vnc -display :0 -auth guess -allow 192.168.1.100 ...
```

## 🐛 常見問題

### Q: 無法連線?

檢查防火牆:
```bash
# 檢查埠是否開放
sudo netstat -tulpn | grep 5900

# 允許 VNC 通過防火牆 (如果使用 ufw)
sudo ufw allow 5900/tcp
```

### Q: 畫面卡頓?

1. 降低色彩深度
2. 使用壓縮
3. 在 VNC Viewer 設定中選擇 "低畫質"

### Q: 滑鼠位置不準?

嘗試添加 `-noxdamage` 參數

### Q: 斷線後無法重新連線?

使用 `-forever` 和 `-loop` 參數

## 📊 效能優化

```bash
# 低頻寬模式
x11vnc -display :0 -auth guess -forever -ncache 10 -ncache_cr

# 快速模式 (區域網路)
x11vnc -display :0 -auth guess -forever -solid

# 禁用游標
x11vnc -display :0 -auth guess -forever -nocursor
```

## 🎯 完整啟動腳本範例

創建一個方便的啟動腳本:

```bash
nano ~/start_vnc.sh
```

內容:

```bash
#!/bin/bash
# 確保密碼檔案存在
if [ ! -f ~/.vnc/passwd ]; then
    echo "請先設定 VNC 密碼: x11vnc -storepasswd"
    exit 1
fi

# 停止現有的 x11vnc
pkill x11vnc

# 啟動 x11vnc
x11vnc -display :0 \
       -auth guess \
       -forever \
       -loop \
       -noxdamage \
       -repeat \
       -rfbauth ~/.vnc/passwd \
       -rfbport 5900 \
       -shared \
       -bg \
       -o ~/x11vnc.log

echo "x11vnc 已啟動在埠 5900"
echo "日誌: ~/x11vnc.log"
```

賦予執行權限:
```bash
chmod +x ~/start_vnc.sh
```

使用:
```bash
~/start_vnc.sh
```

---

💡 **提示**: 如果你需要同時支援多個連線或想要更完整的遠端桌面解決方案,也可以考慮使用 NoMachine 或 AnyDesk。
