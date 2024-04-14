
# 使用方法
## 背景介绍
部署服务的时候，没有https不行，用脚本来自动添加 只需要网址和转发端口的应用，ubuntu环境下可用.计划任务定期执行检查证书状态，自动替换


## 脚本使用方法


### 1 下载并启动docker
```bash
# 下载
git clone https://github.com/kerwin-cn/docker-nginx-certbot.git

# 进入文件夹并启动
cd docker-nginx-certbot

#启动nginx和certbot
docker-compose up -d
```


### 2 配置文件./sites.json

```json
//配置文件如下
[
    {
        "site_name": "example.com",
        "proxy_pass": "http://x.xxx.xx.xxx:8888",
        "is_enabled": false,
        "cert_status": "init"
    },
    {
        "site_name": "abc.example.com",
        "proxy_pass": "http://x.xxx.xx.xxx:8080",
        "is_enabled": false,
        "cert_status": "init"
    }
]


// 修改成自己的网址和转发地址 主要修改 site_name 、proxy_pass 、is_enabled 三项
```

### 3 执行脚本

```bash

chmod +x ./check_sites.sh

./check_sites.sh

#等待安装完成，主要做了 把自己添加计划任务 > 根据配置文件下载证书 > 删减nginx配置 >检查是否需要 续期证书 
#计划任务每天两天执行一次
```

