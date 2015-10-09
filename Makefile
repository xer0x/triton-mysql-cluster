.PHONY: build
.PHONY: deploy
.PHONY: clean
.PHONY: test

boot2docker:
	docker-machine stop default
	docker-machine start default

build: .build-mysql .build-mysql-tester
	@echo happy now

.build-mysql: boot2docker
	eval `docker-machine env default`; docker build -t xer0x/triton-mysql triton-mysql
	eval `docker-machine env default`; cd triton-mysql; docker push xer0x/triton-mysql

.build-mysql-tester:
	eval `docker-machine env default`; \
		cd test; \
		docker build -t xer0x/triton-mysql-tester triton-mysql-tester
	eval `docker-machine env default`; \
		cd test/triton-mysql-tester; \
		docker push xer0x/triton-mysql-tester

deploy:
	docker pull xer0x/triton-mysql
	docker pull xer0x/triton-mysql-tester
	docker-compose --project-name=my up -d --no-recreate --timeout 120

clean: clean-test
	docker-compose --project-name=my stop
	docker-compose --project-name=my rm -f -v master slave
	docker-compose --project-name=my rm -f -v data

clean-test:
	cd test ; \
		docker-compose --project-name=test stop ; \
		docker-compose --project-name=test rm -f -v

#test: clean build deploy
test: clean-test
	docker pull xer0x/triton-mysql-tester
	cd test ; \
		docker-compose --project-name=test up -d --no-recreate --timeout 120
	#docker-compose --project-name=test stop
	#docker-compose --project-name=test rm -f -v

# vim: noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
