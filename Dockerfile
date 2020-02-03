FROM golang:1.13-alpine AS builder

COPY .  /go/src/github.com/x0rzkov/likelo
WORKDIR /go/src/github.com/x0rzkov/likelo

RUN cd /go/src/github.com/x0rzkov/likelo \
 && go install ./cmd/likelo

FROM alpine:3.11 AS runtime

# Install tini to /usr/local/sbin
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-muslc-amd64 /usr/local/sbin/tini

# Install runtime dependencies & create runtime user
RUN apk --no-cache --no-progress add ca-certificates \
 && chmod +x /usr/local/sbin/tini && mkdir -p /opt \
 && adduser -D x0rzkov -h /opt/likelo -s /bin/sh \
 && su x0rzkov -c 'cd /opt/likelo; mkdir -p bin config data'

# Switch to user context
USER x0rzkov
WORKDIR /opt/likelo

# Copy oniontree binary to /opt/oniontree/bin
COPY --from=builder /go/bin/likelo /opt/likelo/bin/likelo
ENV PATH $PATH:/opt/likelo/bin

# Container configuration
VOLUME ["/opt/likelo/data"]
ENTRYPOINT ["tini", "-g", "--"]
CMD ["/opt/likelo/bin/likelo"]
