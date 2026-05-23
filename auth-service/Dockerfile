FROM golang:1.25-alpine3.21 AS builder
# FROM golang:1.25-alpine3.23 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY --exclude=tests/ . .

RUN CGO_ENABLED=0 GOOS=linux go build -o auth-service

FROM alpine:3.23.3 AS final
# FROM alpine:3.23 AS final

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /app/auth-service /app/auth-service

USER appuser

EXPOSE 8001

ENTRYPOINT ["/app/auth-service"]