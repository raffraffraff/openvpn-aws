FROM ubuntu:latest as builder

ENV OPENSSL_VERSION=1.1.1t
ENV LZO_VERSION=2.10
ENV LZ4_VERSION=1.9.2
ENV OPENVPN_VERSION=2.5.9

COPY src /src
COPY fpm /fpm

WORKDIR /

# Install build & package tools
RUN apt-get update
RUN apt-get install -y curl unzip golang build-essential autoconf golang libtool net-tools wget

# Compile server.go
RUN go build /src/server.go && \
    mv server /fpm/src/opt/openvpn-aws/

# Compile OpenSSL
RUN cd / && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xvf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./Configure gcc -static -no-shared && \
    make && \
    make install_sw

# Compile LZO (probably not needed)
RUN cd / && \
    wget http://www.oberhumer.com/opensource/lzo/download/lzo-${LZO_VERSION}.tar.gz && \
    tar -xvf lzo-${LZO_VERSION}.tar.gz && cd lzo-${LZO_VERSION} && \
    ./configure --enable-static --disable-debug && \
    make && \
    make install

# Compile LZ4
RUN cd / && \
    wget https://github.com/lz4/lz4/archive/v${LZ4_VERSION}.tar.gz && \
    tar -xvf v${LZ4_VERSION}.tar.gz && \
    cd lz4-${LZ4_VERSION}/ && \
    make && \
    make install

# Compile openvpn
RUN cd / && \
    curl -L https://github.com/OpenVPN/openvpn/archive/v${OPENVPN_VERSION}.zip -o openvpn.zip && \
    unzip openvpn.zip && \
    cd openvpn-${OPENVPN_VERSION} && \
    patch -p1 < /src/openvpn-${OPENVPN_VERSION}-aws.patch && \
    autoreconf -i -v -f && \
    ./configure --enable-static  --disable-debug --disable-shared --disable-plugins --disable-unit-tests && \
    make LIBS="-all-static" && \
    make install-exec && \
    strip /usr/local/sbin/openvpn && \
    mv /usr/local/sbin/openvpn /fpm/src/opt/openvpn-aws/

# Final image: a package builder that uses FPM
FROM alpine:latest

WORKDIR /build

COPY --from=builder /fpm /build/fpm
COPY entrypoint.sh /

VOLUME /build/output

RUN apk add --no-cache ruby rpm
RUN gem install fpm

ENTRYPOINT /entrypoint.sh
