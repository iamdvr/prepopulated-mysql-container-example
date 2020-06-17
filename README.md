A prepopulated mysql container ?
================================

Yeah why not, i like my test faster :D

But how ?
---------

The mysql/mariadb container image contain an init script that will execute everything in `/docker-entrypoint-initdb.d/`

see `Initializing a fresh instance` @ https://hub.docker.com/_/mysql/

So let's run this initialization in a multi-stage build and copy the initialized DB in the new image :D

(see comments in dockerfile for details of the hack)

Try it!
======

Clone this, then...

```
}> docker build --tag my-prepopulated-image .
...

}> docker run -d --rm --name my-container my-prepopulated-image
...

}> docker logs my-container

(there was is initialization here, therefore we win)

2019-03-06T11:50:00.814536Z 0 [Warning] [MY-011070] [Server] 'Disabling symbolic links using --skip-symbolic-links (or equivalent) is the default. Consider not using this option as it' is deprecated and will be removed in a future release.
2019-03-06T11:50:00.814638Z 0 [System] [MY-010116] [Server] /usr/sbin/mysqld (mysqld 8.0.15) starting as process 1
2019-03-06T11:50:02.662107Z 0 [Warning] [MY-010068] [Server] CA certificate ca.pem is self signed.
2019-03-06T11:50:02.686250Z 0 [Warning] [MY-011810] [Server] Insecure configuration for --pid-file: Location '/var/run/mysqld' in the path is accessible to all OS users. Consider choosing a different directory.
2019-03-06T11:50:02.708834Z 0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.15'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.

}> docker run -it --rm --link my-container mysql:latest mysql -hmy-container -uroot -proot myexample -e "select * from mytable;"
+---------+
| myfield |
+---------+
| Hello   |
| Dolly   |
+---------+
```

additional sql can be initialised with the resulting image,
via mounting sql files into /docker-entrypoint-initdb.d
or preloading the generated image in the same way, using the previous image as a base
>docker run -it --mount type=bind,source="$(pwd)/additional_sql",target=/docker-entrypoint-initdb.d \
        my-prepopulated-image
