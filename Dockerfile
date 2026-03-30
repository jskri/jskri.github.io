# To build the site, from the root:
# docker run --rm -v $(pwd):/workspace -w /workspace ghcr.io/<username>/<imagename>:<tag> make all

FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG PANDOC_VERSION=3.8.3
RUN wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz \
    && tar -xzf pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz \
    && mv pandoc-${PANDOC_VERSION}/bin/pandoc /usr/local/bin/ \
    && rm -rf pandoc-${PANDOC_VERSION}*


FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/pandoc /usr/local/bin/pandoc
