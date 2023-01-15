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
    apk add --no-cache git gcc ca-certificates libc-dev tini-static \
    && update-ca-certificates
WORKDIR /build
COPY . .
RUN go build -ldflags "-w -s" -trimpath -o speedtest .

FROM gcr.io/distroless/static:nonroot
USER nonroot:nonroot
COPY --from=builder --chown=nonroot:nonroot /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder --chown=nonroot:nonroot /build/speedtest /speedtest
COPY --from=builder --chown=nonroot:nonroot /sbin/tini-static /tini
ENTRYPOINT [ "/tini", "--", "/speedtest" ]
LABEL \
    org.opencontainers.image.title="speedtest-go" \
    org.opencontainers.image.source="https://github.com/onedr0p/speedtest-go"
