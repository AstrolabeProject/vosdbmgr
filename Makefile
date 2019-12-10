ENVLOC=/etc/trhenv
IMG=vosdbmgr:devel
JOPTS='_JAVA_OPTIONS -Xms512m -Xmx4096m'
NAME=vosdbmgr
NET=vos_net
STACK=vos
file=vos.sql

.PHONY: help docker exec restore save stop

help:
	@echo 'Make what? help, build, docker, exec, run, stop'
	@echo '  where: help    - show this help message'
	@echo '         docker  - build the container image'
	@echo '         exec    - exec into the running backup/restore (CLI arg: NAME=containerID)'
	@echo '         restore - start a restore (CLI arg: file=dumpFilename)'
	@echo '         save    - start a backup before it finishes (CAUTION!)'
	@echo '         stop    - stop the backup/restore container (for development)'

docker:
	docker build -t ${IMG} .

exec:
	docker cp .bash_env ${NAME}:${ENVLOC}
	docker exec -it ${NAME} bash

restore:
	docker run -it --rm --name ${NAME} --network ${NET} -e ${JOPTS} -v ${PWD}/backups:/backups ${IMG} -c restore -f ${file}

save:
	docker run -it --rm --name ${NAME} --network ${NET} -e ${JOPTS} -v ${PWD}/backups:/backups ${IMG}

stop:
	docker stop ${NAME}
