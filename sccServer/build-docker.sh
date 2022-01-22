#!/bin/bash

#Geração do pacote JAR da aplicação Spring Cloud Config Server
./mvnw package -Dmaven.test.skip=true

# Build da imagem Docker
docker build -t andremf/sccserver:latest -f src/main/resources/Docker/Dockerfile target/

# Push da imagem
docker push andremf/sccserver:latest

# Remoção do diretório target
rm -rf target/