FROM python:3.13.1-slim-bookworm AS build
WORKDIR /app
COPY requirements.in .
RUN set -x && \
    sed -i 's/@SECLEVEL=2/@SECLEVEL=1/' /etc/ssl/openssl.cnf && \
    apt-get update && apt-get -y install git && \
    pip install --no-cache-dir -U pip pip-tools wheel && \
    pip-compile ./requirements.in && \
    pip install --no-cache-dir -r ./requirements.txt && \
    pip uninstall -y pip-tools && \
    apt-get autoremove --purge -y git
# Note: Regarding SECLEVEL, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=927461
# Lowering the SECLEVEL causes more https certificates to be valid.
COPY ircurltitlebot ircurltitlebot
RUN set -x && \
    groupadd -g 999 app && \
    useradd -r -m -u 999 -g app app
USER app
ENTRYPOINT ["python", "-m", "ircurltitlebot"]
CMD ["--config-path", "/config/config.yaml"]
STOPSIGNAL SIGINT

FROM build AS test
WORKDIR /app
USER root
COPY Makefile pylintrc pyproject.toml requirements-dev.in setup.cfg vulture.txt ./
RUN set -x && \
    pip install pip-tools && \
    pip-compile ./requirements-dev.in && \
    pip install --no-cache-dir -U -r requirements-dev.txt && \
    apt-get update && apt-get -y install make && \
    make test

FROM build
