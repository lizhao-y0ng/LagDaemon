#!/bin/bash
# ============================================================
# LagDaemon 安装器
# - 内存：tmpfs+dd 固定占用（默认总内存40%，至少1GB）
# - CPU：多核心持续计算圆周率（bc -l），结果保存至 /tmp/pi_results/
# - 服务持续运行，直到 systemctl stop
# - 项目名称：LagDaemon
# ============================================================

echo ""
echo "   __               __   _          _                 "
echo "  / /  ___   __ _  / _| | |   __ _ | |__    ___   ___ "
echo " / /  / _ \ / _\` | | |_ | |  / _\` || '_ \  / _ \ / _ \\"
echo "/ /__| (_) | (_| | |  _|| | | (_| || | | ||  __/|  __/"
echo "\____/\___/ \__,_| |_|  |_|  \__,_||_| |_| \___| \___|"
echo "                                                       "
echo -e "\033[1;33m            Welcome to LagDaemon 
echo ""

# ---------- 以下是原安装脚本（功能不变） ----------

set -e

# ---------- 颜色（屎山多） ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_MAGENTA='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
LIGHT_WHITE='\033[1;37m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
RESET='\033[0m'

# ---------- 全局变量 ----------
SERVICE_NAME="lagdaemon"
BIN_PATH="/usr/local/bin/${SERVICE_NAME}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
LOG_FILE="/var/log/install_lagdaemon.log"
MEM_SIZE="$1"
USELESS_ARRAY=("foo" "bar" "baz" "qux" "quux")

# ---------- 无用函数（屎山） ----------
do_nothing() {
    local a=0
    while [ $a -lt 10 ]; do
        a=$((a + 1))
        for b in $(seq 1 10); do :; done
    done
}
useless_calc() { local x=$1; local y=$2; echo $((x * y * 3 / 100)) > /dev/null; }
create_temp_file() { touch /tmp/shit_$(date +%s%N).tmp 2>/dev/null || true; }
remove_temp_files() { rm -f /tmp/shit_*.tmp 2>/dev/null || true; }

# ---------- 日志（多输出） ----------
log_info() {
    local msg="$1"
    echo -e "${GREEN}[INFO]${NC} $msg" | tee -a "$LOG_FILE"
    echo "[INFO] $msg" >> "$LOG_FILE" 2>/dev/null
    logger -t "lagdaemon-installer" "$msg" 2>/dev/null || true
}
log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg" | tee -a "$LOG_FILE"
    echo "[WARN] $msg" >> "$LOG_FILE" 2>/dev/null
    logger -t "lagdaemon-installer" "WARN: $msg" 2>/dev/null || true
}
log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg" | tee -a "$LOG_FILE"
    echo "[ERROR] $msg" >> "$LOG_FILE" 2>/dev/null
    logger -t "lagdaemon-installer" "ERROR: $msg" 2>/dev/null || true
    exit 1
}

# ---------- 检查并安装 bc ----------
install_bc() {
    if command -v bc &>/dev/null; then
        log_info "bc 已安装"
        return
    fi
    log_info "安装 bc ..."
    if command -v apt &>/dev/null; then
        apt update -qq && apt install -y bc
    elif command -v dnf &>/dev/null; then
        dnf install -y bc
    elif command -v pacman &>/dev/null; then
        pacman -S --noconfirm bc
    elif command -v zypper &>/dev/null; then
        zypper install -y bc
    else
        log_error "无法自动安装 bc，请手动安装后重试"
    fi
    command -v bc &>/dev/null || log_error "bc 安装失败"
    log_info "bc 安装成功"
}

# ---------- 计算内存大小 ----------
calculate_size() {
    if [ -n "$MEM_SIZE" ]; then
        echo "$MEM_SIZE"
        return
    fi
    local mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_total_mb=$((mem_total_kb / 1024))
    local target_mb=$((mem_total_mb * 40 / 100))
    [ $target_mb -lt 1024 ] && target_mb=1024
    echo "${target_mb}M"
}

# ---------- 部署主脚本（核心屎山） ----------
deploy_binary() {
    log_info "部署主服务脚本到 $BIN_PATH（π计算版）"
    sudo tee "$BIN_PATH" > /dev/null << 'EOF'
#!/bin/bash
# ============================================================
# LagDaemon 核心服务：内存占用 + π计算 CPU 负载
# - 内存：tmpfs+dd 固定占用
# - CPU：每个核心计算 π（bc -l）并保存结果
# ============================================================

MOUNT_POINT="/tmp/memory"
BLOCK_FILE="${MOUNT_POINT}/block"
SIZE="${LAGDAEMON_SIZE:-1G}"
CPU_CORES=$(nproc)
HALF_CORES=$((CPU_CORES / 2))
[ $HALF_CORES -lt 1 ] && HALF_CORES=1
CPU_PIDS=()
PI_DIR="/tmp/pi_results"
mkdir -p "$PI_DIR"

# ---------- 无用垃圾 ----------
__useless_counter=0
__fake_flag=1
do_nothing() { local x=0; while [ $x -lt 5 ]; do x=$((x+1)); for y in {1..10}; do :; done; done; }

# ---------- 内存占用 ----------
start_memory() {
    if [ -d "$MOUNT_POINT" ]; then
        if ! mount | grep -q "$MOUNT_POINT"; then
            mount -t tmpfs -o size=$SIZE tmpfs "$MOUNT_POINT"
        fi
    else
        mkdir -p "$MOUNT_POINT"
        mount -t tmpfs -o size=$SIZE tmpfs "$MOUNT_POINT"
    fi
    local count=$(echo $SIZE | sed 's/[^0-9]//g')
    [ -z "$count" ] && count=1024
    dd if=/dev/zero of="$BLOCK_FILE" bs=1M count=$count 2>/dev/null || true
    echo "内存占用已启动，大小 $SIZE"
}

# ---------- CPU 压测：计算 π ----------
start_cpu() {
    echo "启动 CPU π 计算，使用 $HALF_CORES 个核心"
    for (( i=0; i<$HALF_CORES; i++ )); do
        (
            # 每个核心使用不同精度（5000~15000 位）
            PRECISION=$(( (RANDOM % 10001) + 5000 ))
            OUT_FILE="${PI_DIR}/pi_core_${i}.log"
            while :; do
                # 计算 π 并保存（覆盖）
                echo "scale=$PRECISION; 4*a(1)" | bc -l > "$OUT_FILE" 2>/dev/null
                # 可加微小随机延时避免同步竞争（但保持高CPU）
                sleep 0.05
            done
        ) &
        CPU_PIDS+=($!)
    done
    echo "CPU π 计算已启动，PID: ${CPU_PIDS[*]}，结果保存在 $PI_DIR"
}

# ---------- 清理 ----------
cleanup() {
    echo "正在清理 CPU π 进程..."
    for pid in ${CPU_PIDS[@]}; do
        kill -9 $pid 2>/dev/null || true
    done
    pkill -9 -f "bc -l" 2>/dev/null || true

    echo "清理内存..."
    rm -f "$BLOCK_FILE" 2>/dev/null
    umount "$MOUNT_POINT" 2>/dev/null
    rmdir "$MOUNT_POINT" 2>/dev/null
    echo "清理完成"
}

# ---------- 主入口 ----------
case "$1" in
    start)
        do_nothing
        start_memory
        start_cpu
        trap cleanup SIGTERM SIGINT
        tail -f /dev/null
        ;;
    stop)
        cleanup
        ;;
    *)
        echo "用法: $0 {start|stop}" >&2
        exit 1
        ;;
esac
EOF

    sudo chmod +x "$BIN_PATH"
    log_info "主脚本部署完成（π计算屎山版）"
}

# ---------- 部署 systemd 服务 ----------
deploy_service() {
    local size_val=$(calculate_size)
    log_info "部署 systemd 服务到 $SERVICE_FILE，内存大小: $size_val"
    sudo tee /etc/default/lagdaemon > /dev/null << EOF
LAGDAEMON_SIZE=$size_val
FAKE_VAR=123
EOF
    sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=LagDaemon - 内存+π CPU 占用服务（屎山版）
After=local-fs.target

[Service]
Type=simple
EnvironmentFile=/etc/default/lagdaemon
ExecStart=/usr/local/bin/lagdaemon start
ExecStop=/usr/local/bin/lagdaemon stop
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=15s
User=root
Restart=no

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    log_info "systemd 服务部署完成喵～"
}

# ---------- 启动服务 ----------
start_service() {
    log_info "主人启动服务并设置开机自启...喵～"
    sudo systemctl enable "$SERVICE_NAME" --now
    sleep 3
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "查看 CPU: htop 可见核心被塞满"
        log_info "π 结果保存在: /tmp/pi_results/pi_core_*.log"
        log_info "停止: sudo systemctl stop $SERVICE_NAME"
    else
        log_error "服务启动失败，检查: journalctl -u $SERVICE_NAME -n 50"
    fi
}

# ---------- 卸载 ----------
uninstall() {
    log_warn "卸载服务...，好吧你不要我了"
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    sudo rm -f "$SERVICE_FILE" "$BIN_PATH" /etc/default/lagdaemon
    sudo systemctl daemon-reload
    sudo pkill -9 -f "bc -l" 2>/dev/null || true
    sudo umount /tmp/memory 2>/dev/null || true
    sudo rm -rf /tmp/memory /tmp/pi_results 2>/dev/null || true
    remove_temp_files
    log_info "卸载完成"
    exit 0
}

# ---------- 主入口 ----------
main() {
    [ "$EUID" -ne 0 ] && log_error "请使用 sudo 运行"
    [ "$1" = "uninstall" ] && uninstall

    log_info "=== LagDaemon 安装开始 ==="
    log_info "内存占用: 总内存40%（至少1GB）"
    log_info "CPU占用: 一半核心持续计算圆周率（结果保存）"
    install_bc
    deploy_binary
    deploy_service
    start_service

    log_info "=== 安装完成！CPU 正在计算 π，内存已固定占用 ==="
    log_info "停止: sudo systemctl stop $SERVICE_NAME"
    log_info "卸载: sudo $0 uninstall"
    log_info "屎山代码仅供娱乐，不影响实际功能。"
}

# 执行主函数
main "$@"
