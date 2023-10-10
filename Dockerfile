# Multi-stage build: builder
FROM python:3.10-slim-buster as builder

WORKDIR /app/

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    VIRTUAL_ENVIRONMENT_PATH="/app/.venv"

ENV PATH="$POETRY_HOME/bin:$VIRTUAL_ENVIRONMENT_PATH/bin:$PATH"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    curl \
    && curl -sSL https://install.python-poetry.org | python3 -

# Copy poetry.lock* in case it doesn't exist in the repo
COPY ./pyproject.toml ./poetry.lock* /app/
RUN poetry install --no-root

# Allow installing dev dependencies to run tests
ARG INSTALL_DEV=false
RUN bash -c "if [ $INSTALL_DEV == 'true' ] ; then poetry install --no-root ; else poetry install --no-root --no-dev ; fi"

# Multi-stage build: runtime
FROM python:3.10-slim-buster as runtime

WORKDIR /app/

COPY --from=builder /app/.venv /app/.venv
COPY ./app/ /app/app
COPY ./start.sh /app/start.sh

# Ensure scripts in .venv are executable
RUN chmod +x /app/start.sh \
    && chmod +x /app/.venv/bin/*
    
# Activate virtual environment
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 8000

CMD ./start.sh