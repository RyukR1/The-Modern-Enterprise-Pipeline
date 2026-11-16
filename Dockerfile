# syntax=docker/dockerfile:1
FROM apache/airflow:2.8.1-python3.10

LABEL maintainer="Enterprise Platform Team" \
      org.opencontainers.image.title="Enterprise Modern Data Stack Orchestration Image" \
      org.opencontainers.image.description="Custom Apache Airflow image equipped with dbt, Astronomer Cosmos, and Cloud connectors." \
      org.opencontainers.image.source="https://github.com/enterprise/mds-pipeline"

USER root

# Install system utilities and database client libraries with cleanup to reduce image size
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER airflow

# Upgrade pip & install Python dependencies
COPY --chown=airflow:root requirements.txt /requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /requirements.txt

# Environment configuration for dbt and Astro Cosmos execution
ENV DBT_PROJECT_PATH=/opt/airflow/dbt_project \
    DBT_PROFILES_DIR=/opt/airflow/dbt_project \
    PYTHONUNBUFFERED=1
