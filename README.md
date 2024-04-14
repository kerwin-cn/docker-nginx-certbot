
# 使用方法
## 背景介绍
部署服务的时候，没有https不行，用脚本来自动添加 只需要网址和转发端口的应用，ubuntu环境下可用.计划任务定期执行检查证书状态，自动替换


## 脚本使用方法


### 1 启动docker
```bash
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


// 修改成自己的网址和转发地址
```

### 3 执行脚本

```bash
chmod +x ./check_sites.sh
./check_sites.sh
```

