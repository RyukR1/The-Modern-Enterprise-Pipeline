FROM apache/airflow:2.8.1-python3.10

USER root

# Install system utilities & build toolchain
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

# Copy requirements and install python packages
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /requirements.txt

# Environment variables for dbt execution
ENV DBT_PROJECT_PATH=/usr/local/airflow/dbt_project
ENV DBT_PROFILES_DIR=/usr/local/airflow/dbt_project
