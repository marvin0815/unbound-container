FROM docker.io/library/alpine:3.23 as builder

ARG UNBOUND_VERSION=1.25.1

RUN apk add -U alpine-sdk flex bison openssl-dev expat-dev libevent-dev

RUN git clone -brelease-${UNBOUND_VERSION} https://github.com/NLnetLabs/unbound.git
WORKDIR /unbound
RUN ./configure --enable-shared=no --enable-static=no --prefix=/usr --sysconfdir=/etc --disable-sha1 --disable-dsa --with-libevent
RUN make -j$(nproc)
RUN make strip
RUN make install
RUN /usr/sbin/unbound-anchor || exit 0

FROM docker.io/library/alpine:3.23
RUN apk -U upgrade
RUN apk add ca-certificates libevent
COPY --from=builder /usr/sbin/* /usr/sbin/
RUN install -m 755 -d /etc/unbound
RUN install -m 755 -d /etc/unbound/unbound.conf.d/
COPY --from=builder /etc/unbound/root.key /etc/unbound/
COPY unbound.conf /etc/unbound/
COPY remote.conf /etc/unbound/unbound.conf.d/
RUN addgroup -g 101 unbound
RUN adduser -D -H -h /etc/unbound -g "Unbound User" -s /sbin/nologin -G unbound -u 100 unbound

ENTRYPOINT ["unbound", "-d"]
