FROM postgres:14

MAINTAINER Tom Hicks <hickst@email.arizona.edu>

RUN apt-get update \
    && apt-get install -y --no-install-recommends wget postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /backups

COPY vosdbmgr.sh .pgpass /

ENTRYPOINT [ "/vosdbmgr.sh" ]
CMD [ "-c", "save", "-f", "vos", "--debug" ]
