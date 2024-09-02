.DEFAULT_GOAL := start

start:
	@./start.sh

down:
	docker compose down --remove-orphans

clean:
	docker system prune --all --volumes
	rm -f .env

pull:
	docker compose pull

restart: down start
update: pull restart
