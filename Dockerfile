FROM mysql:5 as base

# A an alternative entrypoint sourced from the original
COPY entrypoint.sh /preloader_entrypoint.sh
RUN chmod +x /preloader_entrypoint.sh
ENTRYPOINT ["/preloader_entrypoint.sh"]
ENV MYSQL_ROOT_PASSWORD rootpass
# if your initdb does not create databases or users needed to start it,
# define those here
# ENV MYSQL_DATABASE app
# ENV MYSQL_USER user
# ENV MYSQL_PASSWORD pass


FROM base as builder
# set DONT_START_MYSQLD so that we can run it without starting the daemon
ENV DONT_START_MYSQLD 'true'

COPY init_db/. /docker-entrypoint-initdb.d/.

# Need to change the datadir to something else that /var/lib/mysql because the parent docker file defines it as a volume.
# https://docs.docker.com/engine/reference/builder/#volume :
#       Changing the volume from within the Dockerfile: If any build steps change the data within the volume after
#       it has been declared, those changes will be discarded.
RUN ["./preloader_entrypoint.sh", "mysqld", "--datadir", "/initialized-db"]


FROM base
COPY --from=builder /initialized-db /var/lib/mysql
