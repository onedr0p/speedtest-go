FROM golang:1.19-alpine AS builder
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT=""
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    GOARM=${TARGETVARIANT}
RUN \
    apk add --no-cache git gcc ca-certificates libc-dev tini-static upx \
    && update-ca-certificates
WORKDIR /build
COPY . .
RUN go build -ldflags "-w -s" -trimpath -o speedtest .
RUN upx ./speedtest

FROM gcr.io/distroless/static:nonroot
USER nonroot:nonroot
ENV SPEEDTEST_BIND_ADDRESS="0.0.0.0" \
    SPEEDTEST_LISTEN_PORT="80"
COPY --from=builder --chown=nonroot:nonroot /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder --chown=nonroot:nonroot /build/speedtest /app/speedtest
COPY --from=builder --chown=nonroot:nonroot /sbin/tini-static /tini
ENTRYPOINT [ "/tini", "--", "/app/speedtest" ]
LABEL \
    org.opencontainers.image.title="speedtest-go" \
    org.opencontainers.image.source="https://github.com/onedr0p/speedtest-go"
