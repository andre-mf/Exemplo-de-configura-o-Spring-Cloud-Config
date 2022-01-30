# Exemplo de implementação do micro-serviço de distribuição de configurações Spring Cloud Config

### 

### 🚀 Por padrão, o seviço é disponibilizado na porta 8888

O Spring Cloud Config utiliza repositórios *git* para prover as configurações. O repositório pode estar armazenado em um seviço (como GitLab ou Github) ou em um diretório.

Nessa configuração, o projeto tem as seguintes dependências:

- Spring Config Server

- Spring Security

Para acesso em serviços gerenciadores de repositórios, uma chave SSH deverá ser configurada.

```shell
ssh-keygen -m PEM -t rsa -b 4096
```

Deve-se incluir a anotação **@EnableConfigServer** no arquivo **SccServerApplication**:

```java
package com.example.sccserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

@EnableConfigServer
@SpringBootApplication
public class SccServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(SccServerApplication.class, args);
    }
}
```

No pacote com.example.sccserver, criar a classe de configuração SecurityConfiguration:

```java
package com.example.sccserver;

import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;

@Configuration
public class SecurityConfiguration extends WebSecurityConfigurerAdapter {

    @Override
    public void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests().antMatchers("/decrypt").denyAll();
        http.authorizeRequests().antMatchers("/encrypt").authenticated().and().csrf().disable();
        super.configure(http);
    }
}
```

Para que o Spring Cloud Config esteja apto a criptografar valores em arquivos de configuraçẽs, pode ser usado criptografia simétrica ou assimétrica com a geração de uma chave RSA. Esta última é utilizada nesse exemplo. Para gerar a chave, execute o comando no terminal (necessário ter a JDK 11 ou superior):

```shell
keytool -genkeypair -alias sccKey -keyalg RSA -dname "CN=Andre,OU=SCC,O=andre.com,L=Brasilia,S=DF,C=BR" -keypass 123456 -keystore sccKey.jks -storepass 123456
```

A chave deverá ser movida para **/resources/key**.

Em seguida, deve-se excluir o arquivo **application.properties** e criar o **application.yml** em seu lugar, pois facilita a edição da configuração:

```yaml
server:
  port: 8888
spring:
  security:
    user:
      name: ${security_user}
      password: ${security_password}
  cloud:
    config:
      server:
        git:
          timeout: 10
          uri: ${config_git_url}
          default-label: main
          ignoreLocalSshSettings: true
          privateKey: ${config_private_key}
          search-paths: '{application}/{profile}'
        encrypt:
          enabled: false

encrypt:
  key-store:
    location: key/sccKey.jks
    password: 123456
    alias: sccKey
    secret: 123456
```

🗝️ Para *encriptar* um valor, o Spring Cloud Config dispõe o *endpoint* **/encrypt**.

Utilizando Postman, por exemplo,  na guia *Authorization*, seleciona-se o tipo *Basic Auth* para informar o usuário e senha definidos para o Spring Security. A resposta da chamada *POST* ao endpoint contém o valor encriptado. Ela deverá ser copiada e colada no arquivo de configuração que estará no repositório *git*. Deve-se adicionar o prefixo **{cipher}**, como ilustra o exemplo:

```yml
spring:
  datasource:
    username: '{cipher}AQBj/PpiG7P9MjmuH9g17CWv...'
    password: '{cipher}AQDyntWfP5fnZIwlUMULK359...'
```

*Obs*: para arquivos application.properties, não é necessário envolver o texto cifrado com aspas simples.

A *decriptação* é realizada no cliente, garantindo que, mesmo em caso de interceptação, a segurança da informação não será prejudicada. Portanto, a chave gerada deverá ser copiada para a aplicação cliente.

Os arquivos no repositório deverão ser nomeados seguindo o padrão **(nomeAplicação)-(perfil).yml** (exemplo: teste-dev.yml).

Com tudo pronto, basta executar o comando para que o Maven realize o *build*:

```shell
./mvnw package -Dmaven.test.skip=true
```

Para geração de uma imagem Docker, no diretório raiz executar:

```shell
./build-docker.sh
```

De acordo com o arquivo **application.yml**, as seguintes variáveis de ambiente devem ser exportadas na execução do arquivo *jar* ou *container* Docker:

- **Spring Security**:
  
  - **security_user**: usuário para *logon*;
  
  - **security_password**: senha de *logon*;

- **Spring Cloud Config**:
  
  - **config_git_url**: endereço do repositório *git*;
  
  - **config_private_key**: chave SSH privada, armazenada em ~/.ssh/id_rsa. Pode ser exportada com $(cat ~/.ssh/id_rsa).

Para execução de *container* Docker, tanto do servidor quanto dos clientes, deve-se criar uma *network*:

```shell
docker network create scc
```

Para iniciar o *container* Docker, executar:

```shell
docker run --name=sccserver -e security_user=admin -e security_password=123456 -e config_git_url="git@gitlab.com:andre-mf/cloudconfig.git" -e config_private_key="$(cat ~/.ssh/id_rsa)" -p 8888:8888 --network=scc andremf/sccserver:latest
```

## 🖥 Configuração da aplicação cliente

A aplicação cliente tem as seguintes dependências:

- Spring Web

- Config Client

Adicionar a dependência **Cloud Bootstrap** ao **pom.xml**:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-bootstrap</artifactId>
</dependency>
```

A chave de criptografia criada para o Spring Cloud Config deve ser copiada para a pasta **Resources/key**.

Na pasta **Resources**, excluir o arquivo application.properties e criar em seu lugar o arquivo **bootstrap.yml**:

```yml
spring:
  application:
    name: teste
  profiles:
    active: dev
  cloud:
    config:
      uri: ${scc_server}:8888
      username: ${security_user}
      password: ${security_password}
encrypt:
  key-store:
    location: key/sccKey.jks
    secret: 123456
    alias: sccKey
    password: 123456
```

Para o *build*, executar o comando:

```shell
./mvnw package -Dmaven.test.skip=true
```

Para geração de uma imagem Docker, no diretório raiz executar:

```shell
./build-docker.sh
```

Na execução do arquivo *jar* ou *container* Docker, exportar as seguintes variáveis:

**Spring Cloud**:

- config:
  
  - **scc_server**: endereço do servidor SCC. Em caso de container, colocar na mesma rede do SCC e informar o nome do container SCC.
  
  - **security_user**: usuário do Spring Security para *logon*;
  
  - **security_password**: senha de *logon*.

Para iniciar o *container* Docker, executar:

```shell
docker run --name=sccclient -e scc_server=sccserver -e security_user=admin -e security_password=123456 -p 8080:8080 --network=scc andremf/sccclient:latest
```
