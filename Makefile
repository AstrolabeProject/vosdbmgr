BAKDIR=${PWD}/backups
ENVLOC=/etc/trhenv
#IMG=vosdbmgr:devel
IMG=astrolabe/vosdbmgr:2.0
NAME=vosdbmgr
NET=vos_net
PGHOST=alwsdb
file=vos

.PHONY: help docker exec restore save stop

help:
	@echo 'Make what? help, docker, exec, restore, save, stop'
	@echo '  where: help    - show this help message'
	@echo '         docker  - build the container image'
	@echo '         exec    - exec into the running backup/restore (CLI arg: NAME=containerID)'
	@echo '         restore - start a restore (CLI arg: file=dump-file-path)'
	@echo '         save    - backup the VOS DB to a file in ./backups'
	@echo '         stop    - stop the backup/restore container before it finishes (CAUTION!)'

docker:
	docker build -t ${IMG} .

exec:
	docker cp .bash_env ${NAME}:${ENVLOC}
	docker exec -it ${NAME} bash

restore:
	docker run -it --rm --name ${NAME} -e PGHOST=${PGHOST} --network ${NET} -v ${BAKDIR}:/backups ${IMG} -c restore -f ${file} -v

save:
	docker run -it --rm --name ${NAME} -e PGHOST=${PGHOST} --network ${NET} -v ${BAKDIR}:/backups ${IMG} -c save -f ${file} -v

stop:
	docker stop ${NAME}

%:
	@:
