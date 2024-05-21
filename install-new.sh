#!/bin/bash

# by https://github.com/heinu123

if [[ "$#" == 0 ]];then
    echo "参数不可为空!"
    exit 0
fi
config=""
update=""
mmdburl="https://jsd.onmicrosoft.cn/gh/Loyalsoldier/geoip@release/Country.mmdb"

main() {
    Update_system
    Get_parameter $@

    if [ ! "$install_path" ]; then
        if [ -d "/opt" ];then
            install_path="/opt/miaospeed"
            mkdir ${install_path}
        else
            echo "/opt目录不存在 将在当前目录安装"
            install_path="$(pwd)/miaospeed"
            mkdir ${install_path}
        fi
    else
        if [ "$(echo $install_path | grep "\.")" ];then
            echo "安装路径必须为绝对路径"
            exit 1
        fi
        if [ ! -d "$install_path" ]; then
            echo "--path参数必须为路径!"
            exit 1
        fi
    fi
    
    if [ '$(echo $mmdb | grep "(http://|https://")' ]; then
        echo "正在下载mmdb数据库..."
        download ${mmdb} ${install_path}/Country.mmdb
        mmdb=${install_path}/Country.mmdb
    fi
    
    if [ "$mmdb" ]; then
        if [ ! -f "$mmdb" ]; then
            echo "--mmdb 文件不存在!"
            exit 1
        else
        mmdb=" -mmdb ${mmdb}"
        fi
    fi
    
    if [ "${token}" != "" ]; then
        config="${config} -token ${token}"
    fi
    if [ "${whitelist}" != "" ]; then
        config="${config} -whitelist ${whitelist}"
    fi
    
    echo "miaospeed路径:${install_path}"
    
    echo "正在下载miaospeed..."
    cd ${install_path}
    download ${url} ${install_path}/miaospeed.tar.gz
    tar -xzvf ${install_path}/miaospeed.tar.gz -C ${install_path}
    rm -rf ${install_path}/miaospeed.tar.gz

    if [ -f ${install_path}/miaospeed.meta ]; then
        miaospeed_bin=miaospeed.meta
    elif [ -f ${install_path}/miaospeed ]; then
        miaospeed_bin=miaospeed
    else
        echo "解压miaospeed失败"
        exit 0
    fi
        
    if command -v systemctl &> /dev/null; then
        Write_systemctl
        systemctl daemon-reload
        systemctl start miaospeed
        systemctl enable miaospeed
        echo "可以使用 systemctl [start/restart/stop/status] miaospeed 来[启动/重启/停止/查看运行状态]miaospeed"
    elif [[ ${nohupstart} ]];then
        Write_sh
        source ${install_path}/run.sh
        echo "bash ${install_path}/run.sh">>/etc/rc.local
    else
        Write_initd
        chmod +x /etc/init.d/miaospeed
        /etc/init.d/miaospeed start
        sudo update-rc.d miaospeed defaults
        echo "可以使用 /etc/init.d/miaospeed [start/stop] miaospeed 来[启动/停止]miaospeed"
    fi
    echo "端口∶${port}"
    if [ "${token}" != "" ]; then
        echo "token为:${token}"
    fi
    if [ "${whitelist}" != "" ]; then
        echo "白名单botid列表:${botid}"
    fi
    echo "启动参数: ${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config}"
}



Update_system() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$ID" in
        ubuntu|debian)
            apt install -y wget tar systemd
            ;;
        arch|manjaro)
            pacman -Sy --noconfirm wget tar systemd
            ;;
        centos|rhel|fedora)
            yum install -y wget tar systemd
            ;;
        *)
            echo "不支持的linux发行版: $ID"
            exit 1
            ;;
        esac
    else
        if [ $(uname -a | grep -q "OpenWrt") ] && [ $(uname -a | grep -q "openwrt") ]; then
            opkg install wget tar systemd
        elif [ "$(echo $PREFIX | grep termux)" ]; then
            pkg install wget tar -y
            nohupstart=true
        else
            echo "无法检测到Linux发行版."
            exit 1
        fi
    fi
}

Get_parameter() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --url)
                url="$2"
                shift 2
                ;;
            --path)
                install_path="$2"
                shift 2
                ;;
            --update)
                update="true"
                shift
                ;;
            --mtls)
                mtls=" -mtls"
                shift
                ;;
            --nospeed)
                nospeed=" -nospeed"
                shift
                ;;
            --pausesecond)
                pausesecond=" -pausesecond $2"
                shift 2
                ;;
            --speedlimit)
                speedlimit=" -speedlimit $2"
                shift 2
                ;;
            --verbose)
                verbose=" -verbose"
                shift
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --connthread)
                connthread=" -connthread $2"
                shift 2
                ;;
            --mmdb)
                mmdb="$2"
                shift 2
                ;;
            --token)
                token="$2"
                shift 2
                ;;
            --whitelist)
                whitelist="$2"
                shift 2
                ;;
            --nohup)
                nohupstart=true
                shift
                ;;
            *)
                echo "未知参数: $1"
                exit 1
                ;;
        esac
    done
    if [ "$url" == "" ]; then
        echo "--url参数不可为空!"
        exit 1
    fi
    if [ "$mmdb" == "loyalsoldier" ]; then
        mmdb=$mmdburl
    fi
    
    if [ "$port" == "" ] || [ $update != "true" ]; then
        echo "--port参数不可为空!"
        exit 1
    fi
}


download() {
    if command -v curl &> /dev/null; then
        curl -C -sL -o $2 "$1"
        
    else
        wget --no-check-certificate -O $2 -c "$1"
    fi
    if [ ! -f "$2" ];then
        echo "文件下载失败 详情: URL: $1 path: $2"
        exit 1
    fi
}

Write_systemctl() {
cat > /etc/systemd/system/miaospeed.service << EOF
[Unit]
Description=miaospeed
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
WorkingDirectory=${install_path}
ExecStart=${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config}
Restart=always
EOF
}

Write_initd() {
cat > /etc/init.d/miaospeed << EOF
#!/bin/bash
START=99
STOP=10

start() {
    echo "Starting miaospeed"
    while true
    do
        if ! ps aux | grep -q "[${miaospeed_bin:0:1}]${miaospeed_bin:1}"; then
            nohup ${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config} > miaospeed.log &
        fi
        sleep 60
    done
}

stop() {
    echo "Stopping miaospeed"
    killall -9 ${miaospeed_bin}
}

case "$1" in
  start)
    # Start the service
    start
    ;;
  stop)
    # Stop the service
    stop
    ;;
  restart)
    # Restart the service
    stop
    start
    ;;
  *)
    echo 'Usage: $0 {start|stop|restart}'
    exit 1
    ;;
esac
EOF
}

Write_sh() {
cat >${install_path}/run.sh << EOF
#!/bin/bash
while true
do
    if ! ps aux | grep -q "[${miaospeed_bin:0:1}]${miaospeed_bin:1}"; then
        nohup ${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config} > miaospeed.log &
    fi
    sleep 60
done
EOF
}


main $@