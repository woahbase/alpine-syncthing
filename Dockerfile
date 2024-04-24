# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
ARG SRCARCH
ARG VERSION
#
ENV \
    S6_USER=alpine \
    SYNCTHING_HOME="/var/syncthing"
#
RUN set -xe \
    && apk add --no-cache --purge -uU \
        curl \
        ca-certificates \
        tzdata \
    && echo "Using version: $SRCARCH / $VERSION" \
    && curl \
        -o /tmp/syncthing-${SRCARCH}-v${VERSION}.tar.gz \
        -jSLN https://github.com/syncthing/syncthing/releases/download/v${VERSION}/syncthing-${SRCARCH}-v${VERSION}.tar.gz \
    && tar zxf /tmp/syncthing-${SRCARCH}-v${VERSION}.tar.gz -C /usr/local \
    && ln -s /usr/local/syncthing-${SRCARCH}-v${VERSION}/syncthing /usr/local/bin \
    && apk del --purge curl \
    && rm -rf /var/cache/apk/* /tmp/*
#
ENV \
    S6_USERHOME=${SYNCTHING_HOME} \
    STGUIADDRESS=0.0.0.0:8384 \
    STHOMEDIR=${SYNCTHING_HOME}/config \
    STNODEFAULTFOLDER=1 \
    STNOUPGRADE=1 \
    SYNCTHING_DATA=${SYNCTHING_HOME}/data
#
COPY root/ /
#
VOLUME ${STHOMEDIR}/ ${SYNCTHING_DATA}/
#
EXPOSE 8384 22000/tcp 22000/udp 21027/udp
#
HEALTHCHECK \
    --interval=2m \
    --retries=5 \
    --start-period=5m \
    --timeout=10s \
    CMD \
    wget --quiet --tries=1 --no-check-certificate -O - ${HEALTHCHECK_URL:-"http://localhost:8384/rest/noauth/health"} \
    | grep -o --color=never OK \
    || exit 1
#
ENTRYPOINT ["/init"]
