#!/bin/bash
# Show all databases in the MariaDB server
mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p${MARIADB_ROOT_PASSWORD} -e "SHOW DATABASES;"
