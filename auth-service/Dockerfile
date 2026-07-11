# --- Stage 1: Build ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copia primeiro o go.mod para aproveitar o cache de layers
# (este repo não versiona go.sum, então geramos junto com o build)
COPY go.mod ./

# Copia o restante do código-fonte
COPY . .

RUN go mod tidy && go mod download

# Compila binário estático (CGO_ENABLED=0) para rodar em imagem mínima
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/auth-service .

# --- Stage 2: Runtime ---
FROM alpine:3.19

# Certificados TLS (necessário para chamadas HTTPS, ex: se for falar com AWS futuramente)
RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/auth-service .

EXPOSE 8001

ENTRYPOINT ["./auth-service"]
