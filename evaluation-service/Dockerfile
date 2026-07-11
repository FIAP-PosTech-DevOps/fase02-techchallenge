# --- Stage 1: Build ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copia primeiro os arquivos de dependências para aproveitar o cache de layers
COPY go.mod go.sum ./
RUN go mod download

# Copia o restante do código-fonte
COPY . .

# Compila binário estático (CGO_ENABLED=0) para rodar em imagem mínima
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/evaluation-service .

# --- Stage 2: Runtime ---
FROM alpine:3.19

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/evaluation-service .

EXPOSE 8004

ENTRYPOINT ["./evaluation-service"]
