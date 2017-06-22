FROM alpine

ENV DOMAIN=${DOMAIN:-"localdomain"} \
    HOSTNAME=${HOSTNAME:-"localhost"} \
    MESSAGE_SIZE_LIMIT=${MESSAGE_SIZE_LIMIT:-"10240000"} \
    USER=${USER:-"mailer"}

RUN apk add --no-cache bash postfix postfix-sqlite postfix-pcre rsyslog
RUN apk add --update nodejs nodejs-npm && npm i npm@latest -g

# Add processing user
RUN adduser -D -u 1000 ${USER}

COPY conf /etc/postfix
COPY rsyslog.conf /etc/rsyslog.conf

# Move handlers
COPY app /app
WORKDIR /app
RUN npm i --production
RUN chown -R ${USER}:${USER} /app
RUN chmod +x /app/*

# Prepare Sqlite data store
RUN mkdir /data
RUN chmod 0777 /data

# expose port for telnet
EXPOSE 25/tcp

# start up the service
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
