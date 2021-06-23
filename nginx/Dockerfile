FROM nginx:1.19.6-alpine

RUN apk add gettext #installs envsubst

COPY src/nginx.conf.envsubst /etc/nginx
COPY src/start.sh /

ENV PORT_HTTP=80
ENV WORKER_CONNECTIONS=1024
ENV WWW_HOME="/usr/share/nginx/html"

ENTRYPOINT ["/bin/sh","/start.sh"]
