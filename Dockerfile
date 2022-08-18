FROM alpine:latest

RUN apk update
RUN apk upgrade
RUN apk add unbound ncurses ca-certificates openssl
COPY start.sh /
COPY unbound.conf /etc/unbound/unbound.conf
RUN chown unbound:unbound /etc/unbound/unbound.conf
RUN touch /var/log/unbound
RUN chown unbound:unbound /var/log/unbound
RUN mkdir -p /var/lib/unbound
RUN chown unbound:unbound /var/lib/unbound
RUN chmod 777 /start.sh
ENTRYPOINT [ "/start.sh" ]
