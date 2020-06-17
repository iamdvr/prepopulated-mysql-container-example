#!/bin/bash

. /entrypoint.sh

_main() {
	# if command starts with an option, prepend mysqld
	if [ "${1:0:1}" = '-' ]; then
		set -- mysqld "$@"
	fi

	# skip setup if they aren't running mysqld or want an option that stops mysqld
	if [ "$1" = 'mysqld' ] && ! _mysql_want_help "$@"; then
		mysql_note "Entrypoint script for MySQL Server ${MYSQL_VERSION} started."

		mysql_check_config "$@"
		# Load various environment variables
		docker_setup_env "$@"
		docker_create_db_directories

		# If container is started as root user, restart as dedicated mysql user
		if [ "$(id -u)" = "0" ]; then
			mysql_note "Switching to dedicated user 'mysql'"
			exec gosu mysql "$BASH_SOURCE" "$@"
		fi

        if [ ! -z "$(ls /docker-entrypoint-initdb.d/)" ] || [ -z "$DATABASE_ALREADY_EXISTS" ]; then
            # there's no database or there are initdb files to process
            docker_verify_minimum_env

            # check dir permissions to reduce likelihood of half-initialized database
            ls /docker-entrypoint-initdb.d/ > /dev/null

            [ -z "$DATABASE_ALREADY_EXISTS" ] && docker_init_database_dir "$@" || mysql_note "Skipping docker_init_database_dir"
            mysql_note "Starting temporary server"
            docker_temp_server_start "$@"
            mysql_note "Temporary server started."
            [ -z "$DATABASE_ALREADY_EXISTS" ] && docker_setup_db || mysql_note "Skipping docker_setup_db"
            docker_process_init_files /docker-entrypoint-initdb.d/*

            mysql_expire_root_user

            mysql_note "Stopping temporary server"
            docker_temp_server_stop
            mysql_note "Temporary server stopped"

            echo
            mysql_note "MySQL init process done. Ready for start up."
            echo
        fi
	fi
	[ -z $DONT_START_MYSQLD ] && exec "$@" || mysql_note "not running $1"
}

# If we are sourced from elsewhere, don't perform any further actions
if ! _is_sourced; then
	_main "$@"
fi
