FROM debian:bookworm-slim@sha256:f06537653ac770703bc45b4b113475bd402f451e85223f0f2837acbf89ab020a

ARG PANDOC_VERSION=3.8.3
RUN echo "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20240801T000000Z bookworm main" > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends make git wget ca-certificates \
    && wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz \
    && tar -xzf pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz \
    && mv pandoc-${PANDOC_VERSION}/bin/pandoc /usr/local/bin/ \
    && rm -rf pandoc-${PANDOC_VERSION}* \
    && apt-get purge -y wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
