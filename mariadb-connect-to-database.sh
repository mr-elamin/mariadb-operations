#!/bin/bash
mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p${MARIADB_ROOT_PASSWORD}
