FROM golang:1.21-alpine AS builder

ARG WIRE_TARGET=./internal/wired/mongo.go
ARG GENERATE_SWAGGER=false

WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN mkdir -p ./docs && \
    go install github.com/google/wire/cmd/wire@latest && \
    if [ "$GENERATE_SWAGGER" = "true" ]; then \
      go install github.com/swaggo/swag/cmd/swag@latest && \
      /go/bin/swag init -g ./cmd/api/main.go -o ./docs --parseInternal --parseDependency; \
    fi && \
    /go/bin/wire "$WIRE_TARGET" && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/todoapi ./cmd/api

FROM alpine:3.21

RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY --from=builder /out/todoapi /usr/local/bin/todoapi
COPY --from=builder /app/docs /app/docs

EXPOSE 8080

ENTRYPOINT ["todoapi"]
