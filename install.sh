#!/bin/bash

# by https://github.com/heinu123

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
    if uname -a | grep -q "OpenWrt"; then
        opkg install wget tar systemd
    elif [ "$TERM_PROGRAM" = "termux" ]; then
        pkg install wget tar -y
        nohupstart=true
    else
        echo "无法检测到Linux发行版."
        exit 1
    fi
fi

if [[ "$#" == 0 ]];then
    echo "参数不可为空!"
    exit 0
fi
config=""
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
            update=true
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


if [ ! "$url" ]; then
    echo "--url参数不可为空!"
    exit 1
fi

if [ ! "$port" ]; then
    echo "--port参数不可为空!"
    exit 1
fi


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
    wget --no-check-certificate -P ${install_path} -O ${install_path}/Country.mmdb ${mmdb}
    mmdb=${install_path}/Country.mmdb
fi

if [ "$mmdb" ]; then
    if [ ! -f "$mmdb" ]; then
        echo "--mmdb参数不可为路径或者不存在!"
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
wget --no-check-certificate -P ${install_path} -O ${install_path}/miaospeed.tar.gz ${url} 
if [ -f ${install_path}/miaospeed.tar.gz ];then
    echo "正在解压miaospeed..."
    tar -xzvf ${install_path}/miaospeed.tar.gz -C ${install_path}
    rm -rf ${install_path}/miaospeed.tar.gz
else
    echo "下载miaospeed失败"
    exit 0
fi
if [ -f ${install_path}/miaospeed.meta ]; then
    miaospeed_bin=miaospeed.meta
elif [ -f ${install_path}/miaospeed ]; then
    miaospeed_bin=miaospeed
else
    echo "解压miaospeed失败"
    exit 0
fi

if [ ! $update ];then
    if command -v systemctl &> /dev/null; then
        echo "systemctl命令存在 使用systemctl运行miaospeed"
        echo "[Unit]\nDescription=miaospeed\nAfter=network.target\n\n\n[Install]\nWantedBy=multi-user.target\n\n\n[Service]\nType=simple\nWorkingDirectory=${install_path}\nExecStart=${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config}\nRestart=always" > /etc/systemd/system/miaospeed.service
        systemctl daemon-reload
        systemctl start miaospeed
        systemctl enable miaospeed
        IP=$(curl -sL ip.sb)
        IP6=$(curl -sL -6 ip.sb)
        echo "公网ipv4地址: ${IP}"
        echo "公网ipv6地址: ${IP6}"
        echo "端口∶${port}"
        if [ "${token}" != "" ]; then
            echo "token为:${token}"
        fi
        if [ "${whitelist}" != "" ]; then
            echo "白名单botid列表:${botid}"
        fi
        echo "启动参数: ${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config}"
        echo "可以使用 systemctl [start/restart/stop/status] miaospeed 来[启动/重启/停止/查看运行状态]miaospeed"
    elif [[ ${nohupstart} ]];then
        echo "#!/bin/bash\n\n\nwhile true\ndo\n    if ! ps aux | grep -q \"[${miaospeed_bin:0:1}]${miaospeed_bin:1}\"; then\n        nohup ${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config} > miaospeed.log &\n    fi\n    sleep 60\ndone">${install_path}/run.sh
        source ${install_path}/run.sh
        echo "bash ${install_path}/run.sh">>/etc/rc.local
        IP=$(curl -sL ip.sb)
        IP6=$(curl -sL -6 ip.sb)
        echo "公网ipv4地址: ${IP}"
        echo "公网ipv6地址: ${IP6}"
        echo "端口∶${port}"
        if [ "${token}" != "" ]; then
            echo "token为:${token}"
        fi
        if [ "${whitelist}" != "" ]; then
            echo "白名单botid列表:${botid}"
        fi
        echo "启动参数: ${install_path}/miaospeed.meta server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config}"
    else
        echo "#!/bin/bash\n\n\nSTART=99\nSTOP=10\n\n\nstart() {\n    echo \"Starting miaospeed\"\n    while true\n    do\n        if ! ps aux | grep -q \"[${miaospeed_bin:0:1}]${miaospeed_bin:1}\"; then\n            nohup ${install_path}/${miaospeed_bin} server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config} > miaospeed.log &\n        fi\n        sleep 60\n    done\n}\n\n\nstop() {\n    echo \"Stopping miaospeed\"\n    killall -9 ${miaospeed_bin}\n}\n\n\ncase \"\$1\" in\n  start)\n    # Start the service\n    start\n    ;;\n  stop)\n    # Stop the service\n    stop\n    ;;\n  restart)\n    # Restart the service\n    stop\n    start\n    ;;\n  *)\n    echo 'Usage: \$0 {start|stop|restart}'\n    exit 1\n    ;;\nesac\n\nexit 0"> /etc/init.d/miaospeed
        chmod +x /etc/init.d/miaospeed
        /etc/init.d/miaospeed start
        sudo update-rc.d miaospeed defaults
        IP=$(curl -sL ip.sb)
        IP6=$(curl -sL -6 ip.sb)
        echo "公网ipv4地址: ${IP}"
        echo "公网ipv6地址: ${IP6}"
        echo "端口∶${port}"
        if [ "${token}" != "" ]; then
            echo "token为:${token}"
        fi
        if [ "${whitelist}" != "" ]; then
            echo "白名单botid列表:${botid}"
        fi
        echo "启动参数: ${install_path}/miaospeed.meta server -bind 0.0.0.0:${port}${mtls}${verbose}${nospeed}${pausesecond}${speedlimit}${connthread}${mmdb}${config}"
        echo "可以使用 /etc/init.d/miaospeed [start/stop] miaospeed 来[启动/停止]miaospeed"
    fi
fi
