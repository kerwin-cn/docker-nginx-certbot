#固定版本
FROM nginx:1.25.4

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

COPY nginx.conf /etc/nginx/
ADD ./startup.sh /opt/startup.sh
RUN sed -i 's/\r//g' /opt/startup.sh
CMD ["/bin/bash", "/opt/startup.sh"]

EXPOSE 80 443