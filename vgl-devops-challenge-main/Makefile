SHELL := /bin/bash
.ONESHELL:

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

shell-be:
	docker compose exec backend bash

shell-fe:
	docker compose exec frontend sh

migrate:
	ansible-playbook -i ops/ansible/inventory.ini ops/ansible/migrate.yml

smoke:
	ansible-playbook -i ops/ansible/inventory.ini ops/ansible/smoke.yml

nuke:
	docker compose down -v --remove-orphans
	docker volume prune -f
