.PHONY: help up down restart logs dbt-deps dbt-run dbt-test test lint clean

help:
	@echo "Enterprise MDS Pipeline CLI Helper"
	@echo "-----------------------------------"
	@echo "make up          - Start local Docker stack (Airflow, MinIO, Postgres)"
	@echo "make down        - Tear down local Docker stack"
	@echo "make dbt-deps    - Install dbt external dependencies"
	@echo "make dbt-run     - Run dbt transformation models locally (DuckDB)"
	@echo "make dbt-test    - Execute dbt data quality tests"
	@echo "make test        - Run Python unit tests and DAG integrity tests via pytest"
	@echo "make lint        - Run SQLFluff linter on dbt SQL models"
	@echo "make clean       - Remove compiled artifacts and cache"

up:
	docker-compose up -d

down:
	docker-compose down -v

restart: down up

logs:
	docker-compose logs -f

dbt-deps:
	cd dbt_project && dbt deps

dbt-run:
	cd dbt_project && dbt run --target dev --profiles-dir .

dbt-test:
	cd dbt_project && dbt test --target dev --profiles-dir .

test:
	pytest tests/ -v

lint:
	sqlfluff lint dbt_project/models --dialect duckdb

clean:
	find . -type d -name "__pycache__" -exec rm -r {} +
	rm -rf dbt_project/target/ dbt_project/dbt_packages/ /tmp/mds_dev.duckdb
