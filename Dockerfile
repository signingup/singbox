FROM golang:1.23-alpine AS builder

RUN apk update && apk add --no-cache git

WORKDIR /singbox
RUN git clone https://github.com/SagerNet/sing-box.git . && git checkout v1.10.2

#build singbox

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG GOPROXY=""
ENV GOPROXY ${GOPROXY}
ENV CGO_ENABLED=1
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH
RUN set -ex \
    && apk add build-base  linux-headers\
    && export COMMIT=$(git rev-parse --short HEAD) \
    && export VERSION=$(go run ./cmd/internal/read_tag) \
    && go build -v -trimpath -tags \
        "with_gvisor,with_quic,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_acme,with_clash_api,with_embedded_tor,staticOpenssl,staticZlib,staticLibevent" \
        -o /go/bin/sing-box \
        -ldflags "-X \"github.com/sagernet/sing-box/constant.Version=$VERSION\" -s -w -buildid=" \
        ./cmd/sing-box

FROM alpine:latest

RUN apk add --no-cache sed tzdata grep dcron openrc bash curl bc keepalived tcptraceroute radvd nano wget ca-certificates iptables ip6tables openssh jq iproute2 net-tools bind-tools htop vim

COPY --from=builder /go/bin/* /usr/local/bin/
# For compat with the previous run.sh, although ideally you should be
# using build_docker.sh which sets an entrypoint for the image.

ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENTRYPOINT ["sing-box"]
