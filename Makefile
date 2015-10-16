.PHONY: build
.PHONY: deploy
.PHONY: clean
.PHONY: test
.PHONY: clean-test2

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
	@docker-compose --project-name=my stop
	@docker-compose --project-name=my rm -f -v master slave
	@docker-compose --project-name=my rm -f -v data

clean-test:
	@cd test ; \
		docker-compose --project-name=test stop ; \
		docker-compose --project-name=test rm -f -v

#test: clean build deploy
test: clean-test
	@docker pull xer0x/triton-mysql-tester
	@cd test ; \
		docker-compose --project-name=test up -d --no-recreate --timeout 120
	#docker-compose --project-name=test stop
	#docker-compose --project-name=test rm -f -v

test2-dev: clean-test2
	@docker run -d --name my_test_2 -v triton-mysql:/triton-mysql --entrypoint='sleep' xer0x/triton-mysql 999999

test2: clean-test2
	@echo DID YOU REMEMEBER: export MYSQL_ROOT_PASSWORD=any_password_will_do to whatever match start.sh
	@echo 'Remember: apt-get update && apt-get install -y vim curl'
	@#@echo Remember: curl https://us-east.manta.joyent.com/drew.miller/public/mysql.backup.tar.gz -o /tmp/backup.tar.gz
	@echo Remember: export TRITON_MYSQL_ROLE=slave
	@echo
	docker run -d --name my_test_2 \
		--entrypoint='sleep' \
		-e TRITON_MYSQL_ROLE=slave \
		xer0x/triton-mysql 999999
	#docker exec -it my_test_2 bash -c 'apt-get update && apt-get install -y vim curl procps'
	docker exec -it my_test_2 bash /import.sh
	@echo
	@echo After: bash /import.sh
	@echo
	@echo Remember: docker exec -it my_test_2 bash
	@echo Remember: bash /triton-entrypoint.sh mysqld
	@echo
	@echo DISCLAIMER: this test is manual :P
	@echo
	@echo ps. replication does not work because we do not have a link to master.
	@echo it is lame that it hides this error
	@echo

# A real test2 needs to connect to my_master_1 to copy the data
# then to upload it to /drew.miller/public/mysql.backup.tar.gz
# then do the usual above
# ...adding a link for replication would be nice too

clean-test2:
	@docker rm -f my_test_2 || true

# vim: noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
