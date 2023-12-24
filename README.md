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

example:

```shell
--connthread 8
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

```shell
wget -O install.sh https://raw.githubusercontent.com/heinu123/install_miaospeed/main/install.sh
bash install.sh --url https://github.com/moshaoli688/miaospeed/releases/download/v4.3.6/miaospeed_4.3.6_linux_amd64.tar.gz --port 9855 --mode token --token miaospeed --mtls --connthread 8
```

