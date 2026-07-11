# --- Stage 1: Build ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copia primeiro os arquivos de dependências para aproveitar o cache de layers
COPY go.mod go.sum ./

# Copia o restante do código-fonte
# (precisa vir ANTES do "go mod tidy": ele só completa o go.sum corretamente
# se conseguir enxergar os imports reais nos arquivos .go)
COPY . .

# go.sum do repositório está incompleto em relação ao go.mod;
# "go mod tidy" completa as entradas de verificação que faltam antes do download.
RUN go mod tidy && go mod download

# Compila binário estático (CGO_ENABLED=0) para rodar em imagem mínima
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/evaluation-service .

# --- Stage 2: Runtime ---
FROM alpine:3.19

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/evaluation-service .

EXPOSE 8004

ENTRYPOINT ["./evaluation-service"]