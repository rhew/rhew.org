FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY main.go .

RUN go build -ldflags="-s -w" -o 8ball main.go

FROM scratch
COPY --from=builder /app/8ball /8ball

EXPOSE 7283

ENTRYPOINT ["/8ball"]
