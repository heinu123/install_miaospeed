# install_miaospeed
一键安装miaospeed脚本

# 参数
---

## --url
> miaospeed tar.gz压缩包下载地址

**无默认下载url**

example:

```shell
--url https://github.com/moshaoli688/miaospeed/releases/download/v4.3.6/miaospeed_4.3.6_linux_amd64.tar.gz
```

## --path(可选)
> miaospeed工作/下载路径

默认路径: `/opt/miaospeed`

example:

```shell
--path /root/miaospeed
```

## --update(可选)

> 仅下载miaospeed

example: 

```shell
--update
```

## --mtls(可选)

> 开启miaospeed的TLS

example:

```shell
--mtls
```

## --port

> 设置miaospeed的运行端口

example:

```shell
--port 9855
```

## --connthread(可选)

> 设置miaospeed的测速线程数量

**默认为64线程**

example:

```shell
--connthread 8
```


## --nospeed(可选)

> 设置miaospeed为禁止测速(仅允许拓扑结构测试 流媒体测试等)

example:

```shell
--nospeed
```

## --pausesecond(可选)

> 设置miaospeed的每次测速任务后暂停时间段(单位:秒)

example:

```shell
--pausesecond 60
```

## --speedlimit(可选)

> 设置miaospeed的测速任务速度限制(单位:字节)

example:

```shell
--speedlimit 1024000
```

## --verbose(可选)

> 设置miaospeed记录日志

example:

```shell
--verbose
```
## --mmdb(可选)

> 将miaospeed的geoip查询重新路由到指定mmdb库

**使用url并且未设置**`--path`参数会将mmdb库文件下载到:`/opt/miaospeed/Country.mmdb`**

example:

local
```shell
--mmdb /opt/miaospeed/Country.mmdb
```
url
```shell
--mmdb https://jsd.onmicrosoft.cn/gh/Loyalsoldier/geoip@release/Country.mmdb
```

## --mode

> 设置miaospeed运行模式

有`token`和`whitelist`两种运行模式


example(token):

```shell
--mode token
```

example(whitelist):

```shell
--mode token
```

## --token

> 设置miaospeed的token

**当**`mode`**参数为** `token`**有效**

example:

```shell
--token miaospeed
```

## --botid

> 设置miaospeed的白名单bot id

**当**`mode`**参数为** `whitelist`**有效**

example:

```shell
--mtls
```

# Example

token模式:
```shell
wget -O install.sh https://raw.githubusercontent.com/heinu123/install_miaospeed/main/install.sh
bash install.sh --url https://github.com/moshaoli688/miaospeed/releases/download/v4.3.6/miaospeed_4.3.6_linux_amd64.tar.gz --port 9855 --mode token --token miaospeed --mtls --mmdb https://jsd.onmicrosoft.cn/gh/Loyalsoldier/geoip@release/Country.mmdb
```

whitelist模式:
```shell
wget -O install.sh https://raw.githubusercontent.com/heinu123/install_miaospeed/main/install.sh
bash install.sh --url https://github.com/moshaoli688/miaospeed/releases/download/v4.3.6/miaospeed_4.3.6_linux_amd64.tar.gz --port 9855 --mode whitelist --botid 114514 --mtls --mmdb https://jsd.onmicrosoft.cn/gh/Loyalsoldier/geoip@release/Country.mmdb
```

