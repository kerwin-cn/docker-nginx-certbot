#!/bin/bash

#添加到计划任务中每天执行一遍
self_path=$(pwd)
#每天两点
TASK="0 2 * * * cd $self_path && ./check_sites.sh"
# 检查crontab中是否有该字符串
if ! crontab -l | grep -q "check_sites"; then
    # # 添加新的cron任务
    (
        crontab -l 2>/dev/null
        echo "$TASK"
    ) | crontab -
fi

# 判断是不是检查
if [ -z "${IS_CHECK+x}" ]; then
    IS_CHECK=false
fi

# 首先安装一下
apt-get install -y jq

# certbot邮箱
if [ -z "${EMAIL+x}" ]; then
    EMAIL="yourem222ail@163.com"
fi

#配置文件可以指定
if [ -z "${JSON_FILE+x}" ]; then
    JSON_FILE="sites.json"
fi

# 获取数组长度
array_length=$(jq '. | length' "$JSON_FILE")
# 遍历数组
for i in $(seq 0 "$(($array_length - 1))"); do
    # 使用 jq 提取第 i 个元素的 name 属性
    site_name=$(jq -r --argjson index "$i" '.[$index].site_name' "$JSON_FILE")
    proxy_pass=$(jq -r --argjson index "$i" '.[$index].proxy_pass' "$JSON_FILE")
    is_enabled=$(jq -r --argjson index "$i" '.[$index].is_enabled' "$JSON_FILE")
    cert_status=$(jq -r --argjson index "$i" '.[$index].cert_status' "$JSON_FILE")
    # 如果下架站点了
    if [ $is_enabled == false ] && [ $cert_status == "installed" ]; then
        #如果失效了，就删除一下
        docker-compose exec certbot certbot delete --cert-name "$site_name" --non-interactive
        jq ".[$i].cert_status = \"removed\"" "$JSON_FILE" >data.json.tmp && mv data.json.tmp "$JSON_FILE"
        if [ -e nginx/conf.d/"$site_name"-https.conf ]; then
            rm -f nginx/conf.d/"$site_name"-https.conf
        fi
        echo "========>删除了【$site_name】的证书"
    fi

    # 如果
    if [ $is_enabled == false ] && [ -e nginx/conf.d/"$site_name"-https.conf ]; then
        #删除一下配置文件
        rm -f "nginx/conf.d/$site_name-https.conf"
        echo "========>删除了【$site_name】的nginx配置文件"
    fi

    if [ $is_enabled == true ]; then
        if [ ! $cert_status == "installed" ]; then
            #获取证书
            docker-compose exec certbot certbot certonly --webroot -w /var/www/letsencrypt -d "$site_name" --agree-tos --email \
                "$EMAIL" --non-interactive --text
            jq ".[$i].cert_status = \"installed\"" "$JSON_FILE" >data.json.tmp && mv data.json.tmp "$JSON_FILE"
            echo "========>申请了【$site_name】的证书"
        fi
        if [ ! -e nginx/conf.d/"$site_name"-https.conf ]; then
            echo "# 程序自动生成
server {
    listen 80;
    server_name $site_name;
    return 301 https://${site_name}\$request_uri;
}
server {
    listen 443 ssl;
    server_name $site_name;

    ssl_certificate /etc/letsencrypt/archive/$site_name/fullchain1.pem;
    ssl_certificate_key /etc/letsencrypt/archive/$site_name/privkey1.pem;

    location / {
        proxy_pass $proxy_pass;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}" >nginx/conf.d/"$site_name"-https.conf
            echo "========>添加了【$site_name】的配置文件"
        fi
    fi
done

#维护一下证书
docker-compose exec certbot certbot renew
echo "========>检查了【所有的】的证书是否过期"

#检测并改成新证书名称为1
for i in $(seq 0 "$(($array_length - 1))"); do
    site_name=$(jq -r --argjson index "$i" '.[$index].site_name' "$JSON_FILE")
    if [ -e data/nginx/letsencrypt/archive/"$site_name"/fullchain2.pem ]; then
        mv data/nginx/letsencrypt/archive/"$site_name"/cert2.pem data/nginx/letsencrypt/archive/"$site_name"/cert1.pem
        mv data/nginx/letsencrypt/archive/"$site_name"/chain2.pem data/nginx/letsencrypt/archive/"$site_name"/chain1.pem
        mv data/nginx/letsencrypt/archive/"$site_name"/fullchain2.pem data/nginx/letsencrypt/archive/"$site_name"/fullchain1.pem
        mv data/nginx/letsencrypt/archive/"$site_name"/privkey2.pem data/nginx/letsencrypt/archive/"$site_name"/privkey1.pem

        echo "========>更新了【$site_name】的证书文件========="
    fi
done

#更新一下nginx配置
docker-compose exec nginx nginx -s reload
echo "========>重启了nginx============"
