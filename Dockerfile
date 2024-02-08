FROM alpine:latest as libgmpris-fetcher
RUN apk add --no-cache wget
ENV LIBGMPRIS_VERSION="2.2.1-10"
ENV LIBGMPRIS="libgmpris_${LIBGMPRIS_VERSION}_amd64.deb"
RUN wget -O /tmp/libgmpris.deb "https://www.sonarnerd.net/src/jammy/${LIBGMPRIS}"
################################################################################
FROM alpine:latest as hqplayerd-fetcher
RUN apk add --no-cache wget
ENV HQPLAYERD_VERSION="hqplayerd_5.41-11avx2"
ENV HQPLAYERD="hqplayerd_${HQPLAYERD_VERSION}_amd64.deb"
RUN wget -O /tmp/hqplayerd.deb "https://www.signalyst.eu/bins/hqplayerd/jammy/${HQPLAYERD}"
################################################################################
FROM rocm/dev-ubuntu-22.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y \
    gnupg2 \
    libnuma-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd render
RUN wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | apt-key add -
RUN echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ ubuntu main' | tee /etc/apt/sources.list.d/rocm.list

COPY --from=libgmpris-fetcher /tmp/libgmpris.deb /tmp/libgmpris.deb
COPY --from=hqplayerd-fetcher /tmp/hqplayerd.deb /tmp/hqplayerd.deb
RUN apt-get update && apt-get install --no-install-recommends -y \
    /tmp/libgmpris.deb \
    /tmp/hqplayerd.deb \
    && rm /tmp/hqplayerd.deb \
    && rm /tmp/libgmpris.deb \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove \
    && apt-get clean

# run
ENV LD_LIBRARY_PATH="/opt/rocm-4.5.0/hip/lib/:${LD_LIBRARY_PATH}"
RUN hqplayerd -s hqplayer hqplayer
ENV HOME="/mnt/user/appdata/hqplayerd/home"
ENTRYPOINT ["/usr/bin/hqplayerd"]
