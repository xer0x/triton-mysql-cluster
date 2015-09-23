
.PHONY: build

build: .build-mysql
	@echo happy now

.build-mysql:
	eval `docker-machine env default`; docker build -t xer0x/triton-mysql triton-mysql
	eval `docker-machine env default`; cd triton-mysql; docker push xer0x/triton-mysql
