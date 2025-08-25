FROM golang:1.25-alpine AS builder

RUN apk update && apk add --no-cache git

WORKDIR /singbox
RUN git clone https://github.com/SagerNet/sing-box.git . && git checkout v1.12.3

#build singbox

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG GOPROXY=""
ENV GOPROXY ${GOPROXY}
ENV CGO_ENABLED=0
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH
RUN set -ex \
    && apk add build-base  linux-headers\
    && export COMMIT=$(git rev-parse --short HEAD) \
    && export VERSION=$(go run ./cmd/internal/read_tag) \
    && go build -v -trimpath -tags \
        "with_gvisor,with_quic,with_dhcp,with_wireguard,with_utls,with_acme,with_clash_api,with_embedded_tor,staticOpenssl,staticZlib,staticLibevent,with_tailscale" \
        -o /go/bin/sing-box \
        -ldflags "-X \"github.com/sagernet/sing-box/constant.Version=$VERSION\" -s -w -buildid=" \
        ./cmd/sing-box

FROM scratch

COPY --from=builder /go/bin/sing-box /usr/local/bin/sing-box
COPY --from=builder /etc/ssl /etc/ssl

ENTRYPOINT ["sing-box"]
