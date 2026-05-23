FROM golang:1.25-alpine3.23 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY --exclude=tests/ . .

RUN CGO_ENABLED=0 GOOS=linux go build -o evaluation-service

FROM alpine:3.23 AS final

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /app/evaluation-service /app/evaluation-service

USER appuser

EXPOSE 8004

ENTRYPOINT ["/app/evaluation-service"]