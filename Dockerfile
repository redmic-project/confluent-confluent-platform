FROM ellerbrock/alpine-bash-curl-ssl

LABEL maintainer="info@redmic.es"

ENV CONNECT_ADDRS="connect:8083"

COPY scripts/ /

ENTRYPOINT ["sh", "-c", "/docker-entrypoint.sh ${CONNECT_ADDRS}"]
