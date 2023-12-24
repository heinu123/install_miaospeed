#!/bin/bash


# by https://github.com/heinu123


if [ "$(id -u)" -ne 0 ]; then
    echo "使用root用户执行."
    exit 1
fi

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
    else
        echo "无法检测到Linux发行版."
        exit 1
    fi
fi

if [[ "$#" == 0 ]];then
    echo "参数不可为空!"
    exit 0
fi
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --url)
            url="$2"
            shift
            ;;
        --path)
            install_path="$2"
            shift
            ;;
        --update)
            update=true
            shift
            ;;
        --mtls)
            mtls="-mtls"
            shift
            ;;
        --port)
            port="$2"
            shift
            ;;
        --connthread)
            connthread="-connthread $2"
            shift
            ;;
        --mode)
            mode="$2"
            shift
            ;;
        --token)
            token="$2"
            shift
            ;;
        --botid)
            botid="$2"
            shift
            ;;
        *)
            ;;
    esac
    shift
done
if [ ! "$url" ]; then
    echo "--url参数不可为空!"
    exit 1
fi

if [ ! "$port" ]; then
    echo "--port参数不可为空!"
    exit 1
fi

if [ ! "$mode" ]; then
    echo "--mode参数不可为空!"
    exit 1
fi

if [ ! "$install_path" ]; then
    install_path="/opt/miaospeed"
else
    if [ ! -d "$install_path" ]; then
        echo "--path参数必须为路径!"
        exit 1
    fi
fi


if [ "${mode}" == "token" ]; then
    if [ "${token}" == "" ]; then
        echo "--token参数不可为空!"
        exit 0
    fi
    config="-token ${token}"
elif [ "${mode}" == "whitelist" ]; then
    if [ "${botid}" == "" ]; then
        echo "--botid参数不可为空!"
        exit 0
    fi
    config="-whitelist ${botid}"
else
    echo "无效的--mode参数"
    exit 0
fi
echo "miaospeed路径:${install_path}"

echo "正在下载miaospeed..."
mkdir ${install_path}
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

if [ -f ${install_path}/miaospeed.meta ];then
    chmod +x ${install_path}/miaospeed.meta
else
    echo "解压miaospeed失败"
    exit 0
fi



if command -v systemctl &> /dev/null; then
    echo "systemctl命令存在 使用systemctl运行miaospeed"
echo "[Unit]
Description=miaospeed
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
WorkingDirectory=${install_path}
ExecStart=${install_path}/miaospeed.meta server -bind 0.0.0.0:${port} ${mtls} ${config} ${connthread}
Restart=alway" > /etc/systemd/system/miaospeed.service
    systemctl daemon-reload
    systemctl start miaospeed
    systemctl enable miaospeed
    echo "可以使用 systemctl [start/restart/stop] miaospeed 来[启动/重启/停止]miaospeed"
else
    echo "
#!/bin/sh /etc/rc.common

START=99
STOP=10

start() {
    echo 'Starting miaospeed'
    ${install_path}/miaospeed.meta server -bind 0.0.0.0:${port} ${mtls} ${config} ${connthread} &
}

stop() {
    echo 'Stopping miaospeed'
    killall -9 miaospeed.meta
}"> /etc/init.d/miaospeed
    chmod +x /etc/init.d/miaospeed
    /etc/init.d/miaospeed start
    /etc/init.d/miaospeed enable
fi
