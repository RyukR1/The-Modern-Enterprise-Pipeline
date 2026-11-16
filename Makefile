.PHONY: help up down restart logs dbt-deps dbt-run dbt-test test lint lint-py lint-sql docker-build tf-fmt clean

help:
	@echo "Enterprise MDS Pipeline CLI Helper"
	@echo "-----------------------------------"
	@echo "make up           - Start local Docker stack (Airflow, MinIO, Postgres, Prometheus, Grafana)"
	@echo "make down         - Tear down local Docker stack"
	@echo "make restart      - Restart local Docker stack"
	@echo "make logs         - Stream container logs"
	@echo "make docker-build - Build custom Airflow Docker container image"
	@echo "make dbt-deps     - Install dbt external dependencies"
	@echo "make dbt-run      - Run dbt transformation models locally (DuckDB)"
	@echo "make dbt-test     - Execute dbt data quality tests"
	@echo "make test         - Run Python unit tests and DAG integrity tests via pytest"
	@echo "make lint         - Run all linters (Ruff + SQLFluff)"
	@echo "make lint-py      - Run Python linter (Ruff)"
	@echo "make lint-sql     - Run SQLFluff linter on dbt SQL models"
	@echo "make tf-fmt       - Format Terraform infrastructure files"
	@echo "make clean        - Remove compiled artifacts and cache"

up:
	docker compose up -d

down:
	docker compose down -v

restart: down up

logs:
	docker compose logs -f

docker-build:
	docker build -t enterprise-mds-airflow:latest .

dbt-deps:
	cd dbt_project && dbt deps

dbt-run:
	cd dbt_project && dbt run --target dev --profiles-dir .

dbt-test:
	cd dbt_project && dbt test --target dev --profiles-dir .

test:
	pytest tests/ -v

lint: lint-py lint-sql

lint-py:
	ruff check dags/ tests/

lint-sql:
	sqlfluff lint dbt_project/models --dialect duckdb --ignore parsing,templating

tf-fmt:
	terraform fmt -recursive terraform/

clean:
	find . -type d -name "__pycache__" -exec rm -r {} +
	rm -rf dbt_project/target/ dbt_project/dbt_packages/ /tmp/mds_dev.duckdb .pytest_cache/ .ruff_cache/
