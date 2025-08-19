# syntax=docker/dockerfile:1

ARG CLOUDSMITH_WORKSPACE
ARG CLOUDSMITH_REPOSITORY

# ---------- Stage 1: Build with secret and dev base image ----------

FROM docker.cloudsmith.io/${CLOUDSMITH_WORKSPACE}/${CLOUDSMITH_REPOSITORY}/chainguard/python:latest-dev AS dev

ARG CLOUDSMITH_SERVICE
ARG CLOUDSMITH_WORKSPACE
ARG CLOUDSMITH_REPOSITORY
ARG CLOUDSMITH_API_KEY

WORKDIR /flask-app

RUN python -m venv venv
ENV PATH="/flask-app/venv/bin":$PATH
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt --index-url https://$CLOUDSMITH_SERVICE:$CLOUDSMITH_API_KEY@dl.cloudsmith.io/basic/$CLOUDSMITH_WORKSPACE/$CLOUDSMITH_REPOSITORY/python/simple/

# ---------- Stage 2: Final runtime image ----------

FROM docker.cloudsmith.io/${CLOUDSMITH_WORKSPACE}/${CLOUDSMITH_REPOSITORY}/chainguard/python:latest

WORKDIR /flask-app

COPY app.py app.py
COPY --from=dev /flask-app/venv /flask-app/venv
ENV PATH="/flask-app/venv/bin:$PATH"

EXPOSE 8000

ENTRYPOINT ["python", "-m", "gunicorn", "-b", "0.0.0.0:8000", "app:app"]


