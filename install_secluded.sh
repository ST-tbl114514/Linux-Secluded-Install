#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/root/Secluded"
REPO_URL="https://hk.gh-proxy.org/https://github.com/MCSQNXY/Secluded-arm64-linux.git"

clear
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}    Secluded 一键安装脚本${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}检测到已安装 Secluded，正在删除旧版本...${NC}"
    rm -rf "$INSTALL_DIR"
fi

echo -e "${GREEN}开始自动安装 Secluded...${NC}"
echo ""

echo -e "${GREEN}[1/7] 检查依赖...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}正在安装 git...${NC}"
    apt-get update && apt-get install -y git
fi

echo -e "${GREEN}[2/7] 克隆仓库...${NC}"
git clone "$REPO_URL" "$INSTALL_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}克隆失败，请检查网络连接${NC}"
    exit 1
fi

echo -e "${GREEN}[3/7] 创建管理脚本...${NC}"
cat > /usr/local/bin/sec << 'EOFSCRIPT'
#!/bin/bash
INSTALL_DIR="/root/Secluded"
LAUNCHER="SecludedLauncher.out.sh"
PID_FILE="/tmp/secluded.pid"
CONFIG_FILE="$INSTALL_DIR/config.conf"

check_install() {
    if [ ! -d "$INSTALL_DIR" ] || [ ! -f "$INSTALL_DIR/$LAUNCHER" ]; then
        echo "错误: Secluded未安装"
        exit 1
    fi
}

start_service() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "服务已运行"
        return
    fi
    cd "$INSTALL_DIR"
    chmod +x "$LAUNCHER"
    nohup ./"$LAUNCHER" > /tmp/secluded.log 2>&1 &
    echo $! > "$PID_FILE"
    echo "已启动 PID: $(cat $PID_FILE)"
}

stop_service() {
    if [ ! -f "$PID_FILE" ]; then
        echo "服务未运行"
        return
    fi
    kill $(cat "$PID_FILE") 2>/dev/null && rm -f "$PID_FILE" && echo "已停止" || echo "停止失败"
}

show_menu() {
    clear
    echo "======== Sec管理菜单 ========"
    echo "1. 启动服务"
    echo "2. 停止服务"
    echo "3. 重启服务"
    echo "4. 查看状态"
    echo "5. 设置访问地址"
    echo "6. 设置端口"
    echo "7. 设置令牌"
    echo "8. SSL开关"
    echo "9. 查看日志"
    echo "0. 退出"
    echo "============================"
}

if [ $# -gt 0 ]; then
    case "$1" in
        start) check_install; start_service ;;
        stop) stop_service ;;
        restart) stop_service; sleep 1; check_install; start_service ;;
        status) [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null && echo "运行中" || echo "未运行" ;;
        clear) clear ;;
        fa) echo "fa $2" >> "$CONFIG_FILE"; echo "地址已设置" ;;
        fp) echo "fp $2" >> "$CONFIG_FILE"; echo "端口已设置" ;;
        ft) echo "ft $2" >> "$CONFIG_FILE"; echo "令牌已设置" ;;
        fe) echo "fe $2" >> "$CONFIG_FILE"; echo "SSL已设置" ;;
    esac
    exit 0
fi

while true; do
    show_menu
    read -p "选择: " choice
    case $choice in
        1) check_install; start_service; read -p "回车继续" ;;
        2) stop_service; read -p "回车继续" ;;
        3) stop_service; sleep 1; check_install; start_service; read -p "回车继续" ;;
        4) [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null && echo "运行中" || echo "未运行"; read -p "回车继续" ;;
        5) read -p "地址: " v; echo "fa $v" >> "$CONFIG_FILE"; read -p "回车继续" ;;
        6) read -p "端口: " v; echo "fp $v" >> "$CONFIG_FILE"; read -p "回车继续" ;;
        7) read -p "令牌: " v; echo "ft $v" >> "$CONFIG_FILE"; read -p "回车继续" ;;
        8) read -p "1开/0关: " v; echo "fe $v" >> "$CONFIG_FILE"; read -p "回车继续" ;;
        9) tail -30 /tmp/secluded.log 2>/dev/null || echo "无日志"; read -p "回车继续" ;;
        0) exit 0 ;;
    esac
done
EOFSCRIPT

chmod +x /usr/local/bin/sec
ln -sf /usr/local/bin/sec /usr/local/bin/secluded

echo -e "${GREEN}[4/7] 启动服务...${NC}"
cd "$INSTALL_DIR"
chmod +x SecludedLauncher.out.sh
nohup ./SecludedLauncher.out.sh > /tmp/secluded.log 2>&1 &
echo $! > /tmp/secluded.pid
sleep 2

echo -e "${GREEN}[5/7] 配置服务...${NC}"
sec fa 0.0.0.0
sec fp 9906
sec ft STNB

echo -e "${GREEN}[6/7] 获取外网IP...${NC}"
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "获取失败")

echo ""
echo -e "${GREEN}[7/7] 安装完成！${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}访问地址: ${YELLOW}http://${PUBLIC_IP}:9906/index.html?token=STNB${NC}"
echo -e "${GREEN}令牌: ${YELLOW}STNB${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${GREEN}管理命令:${NC}"
echo -e "  sec          - 打开管理菜单"
echo -e "  sec start    - 启动服务"
echo -e "  sec stop     - 停止服务"
echo -e "  sec status   - 查看状态"
echo ""
