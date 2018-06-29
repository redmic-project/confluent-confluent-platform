FROM ellerbrock/alpine-bash-curl-ssl

ENV CONNECT_ADDRS="connect:8083"

COPY scripts/ /

ENTRYPOINT ["sh", "-c", "/docker-entrypoint.sh ${CONNECT_ADDRS}"]
