# Image to generate the blog and publish it.
#
# Generation
# ==========
#
# To generate the blog, type at the root:
#
# ```
# docker build -t blog-builder:latest .
# docker run --rm --user=$(id -u) -v $(pwd):/workspace -w /workspace blog-builder:latest make all
# ```
#
# The site is generated in `dist/`. To serve it locally:
#
# ```
# cd dist/
# python3 -m http 8000
# ```
#
# Publication
# ===========
#
# Publication is done in the CI by the github action peaceiris/actions-gh-pages,
# that requires git and ca-certificates are (see
# .github/workflows/build-site.yml).

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
