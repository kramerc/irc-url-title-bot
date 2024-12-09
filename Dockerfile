FROM python:3.13.1-slim-bookworm as build
WORKDIR /app
COPY requirements.txt .
RUN set -x && \
    sed -i 's/@SECLEVEL=2/@SECLEVEL=1/' /etc/ssl/openssl.cnf && \
    apt-get update && apt-get -y install git && \
    pip install --no-cache-dir -U pip wheel && \
    pip install --no-cache-dir -r ./requirements.txt && \
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

FROM build as test
WORKDIR /app
USER root
COPY Makefile pylintrc pyproject.toml requirements-dev.in setup.cfg vulture.txt ./
RUN set -x && \
    pip install --no-cache-dir -U -r requirements-dev.in && \
    apt-get update && apt-get -y install make && \
    make test

FROM build
