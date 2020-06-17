FROM mysql:5 as builder

# A an alternative entrypoint sourced from the original
COPY entrypoint.sh /preloader_entrypoint.sh
RUN chmod +x /preloader_entrypoint.sh
ENTRYPOINT ["/preloader_entrypoint.sh"]

# needed for intialization
ENV MYSQL_DATABASE app
ENV MYSQL_ROOT_PASSWORD=rootpass
ENV MYSQL_USER 'user'
ENV MYSQL_PASSWORD 'pass'
# set DONT_START_MYSQLD so that we can run it without starting the daemon
ENV DONT_START_MYSQLD 'true'

COPY init_db/. /docker-entrypoint-initdb.d/.

# Need to change the datadir to something else that /var/lib/mysql because the parent docker file defines it as a volume.
# https://docs.docker.com/engine/reference/builder/#volume :
#       Changing the volume from within the Dockerfile: If any build steps change the data within the volume after
#       it has been declared, those changes will be discarded.
RUN ["./preloader_entrypoint.sh", "mysqld", "--datadir", "/initialized-db"]


FROM mysql:5

ENTRYPOINT ["/preloader_entrypoint.sh"]
ENV MYSQL_DATABASE app
ENV MYSQL_ROOT_PASSWORD=rootpass
ENV MYSQL_USER 'user'
ENV MYSQL_PASSWORD 'pass'
COPY entrypoint.sh /preloader_entrypoint.sh
RUN chmod +x /preloader_entrypoint.sh


COPY --from=builder /initialized-db /var/lib/mysql
