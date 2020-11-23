
docker      : Dockerfile
	docker build -t ylosev/aop:latest .

push	: docker
	docker push ylosev/aop:latest
