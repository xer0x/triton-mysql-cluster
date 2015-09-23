.PHONY: build
.PHONY: deploy

build: .build-mysql .build-mysql-cloner
	@echo happy now

.build-mysql:
	docker-machine start default
	eval `docker-machine env default`; docker build -t xer0x/triton-mysql triton-mysql
	eval `docker-machine env default`; cd triton-mysql; docker push xer0x/triton-mysql

.build-mysql-cloner:
	docker-machine start default
	eval `docker-machine env default`; docker build -t xer0x/triton-mysql-cloner triton-mysql-cloner
	eval `docker-machine env default`; cd triton-mysql-cloner; docker push xer0x/triton-mysql-cloner

#deploy:
deploy:
	docker pull xer0x/triton-mysql
	docker pull xer0x/triton-mysql-cloner
	docker-compose --project-name=my up -d --no-recreate --timeout 120
