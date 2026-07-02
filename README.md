# SSH Validation Script

Script Bash para validar conectividade SSH em múltiplos hosts de forma rápida e segura.

## 📋 Descrição

Este script testa a conectividade SSH em uma lista de hosts, fornecendo feedback visual sobre o status de cada conexão. Opcionalmente, também pode coletar informações de espaço em disco dos hosts.

### Funcionalidades

- ✅ Validação de conectividade SSH em múltiplos hosts
- 🔐 Autenticação por senha (segura, não exibe a senha)
- 📊 Opcional: coleta de informações de espaço em disco (`/home/`)
- 🎨 Saída colorida para fácil visualização dos resultados
- ⏱️ Timeout de 30 segundos por conexão
- 🔍 Suporte a comentários no arquivo de hosts
- ✔️ Validação de erros específicos (permissão, timeout)

## 📦 Pré-requisitos

- `bash` (versão 4.0+)
- `sshpass` - para autenticação por senha
- `ssh` - cliente SSH padrão
- Acesso à rede dos hosts

### Instalação de dependências

**Ubuntu/Debian:**
```bash
sudo apt-get install sshpass
```

**RedHat/CentOS:**
```bash
sudo yum install sshpass
```

**macOS:**
```bash
brew install sshpass
```

## 📂 Estrutura de arquivos

```
.
├── validar_ssh.sh    # Script principal
├── hosts.txt         # Lista de hosts para validação
└── README.md         # Este arquivo
```

## 🚀 Uso

### Modo básico (apenas validação de conectividade)

```bash
./validar_ssh.sh
```

Ou especificando um arquivo de hosts customizado:

```bash
./validar_ssh.sh /caminho/para/hosts.txt
```

### Modo com estatísticas de disco

Use a flag `-s` para incluir informações de espaço em disco:

```bash
./validar_ssh.sh -s
```

Ou com arquivo customizado:

```bash
./validar_ssh.sh -s /caminho/para/hosts.txt
```

## 📝 Formato do arquivo hosts.txt

Cada linha deve conter um hostname ou IP:

```
servidor1.example.com
192.168.1.10
servidor2.example.com

# Linhas em branco e comentários são ignorados
# servidor3.example.com
servidor4.example.com
```

## 📊 Saída do script

### Modo básico

```
servidor1.example.com - OK
servidor2.example.com - Permission denied
servidor3.example.com - Host unavailable
```

### Modo com estatísticas de disco (-s)

```
servidor1.example.com
Filesystem     Size  Used Avail Use% Mounted on
/dev/sda1      100G   50G   50G  50% /home/
Status: OK

servidor2.example.com
Connection refused
Status: Host unavailable
```

## 🎨 Códigos de cores

- 🟢 **Verde** - Conectividade OK
- 🟡 **Amarelo** - Permissão negada
- 🔴 **Vermelho** - Host indisponível / timeout

## ⚙️ Opções de configuração

O script oferece as seguintes configurações via SSH:

| Opção | Valor |
|-------|-------|
| StrictHostKeyChecking | no (aceita hosts desconhecidos) |
| ConnectTimeout | 30 segundos |
| NumberOfPasswordPrompts | 1 |
| PreferredAuthentications | password |

Essas configurações podem ser modificadas diretamente no script se necessário.

## 🔒 Segurança

- A senha SSH **não é exibida** na tela (entrada segura)
- A senha **não é armazenada** em variáveis permanentes
- O script usa `StrictHostKeyChecking=no` para ambientes automatizados
- Trata chaves desconhecidas graciosamente

## 🐛 Troubleshooting

### Erro: "sshpass não encontrado"

Instale o pacote conforme instruções na seção [Pré-requisitos](#pré-requisitos).

### Erro: "lista de hosts não encontrada"

Verifique se o arquivo `hosts.txt` existe no diretório do script ou forneça o caminho correto:

```bash
./validar_ssh.sh /caminho/completo/hosts.txt
```

### Todos os hosts retornam "Host unavailable"

- Verifique conectividade básica: `ping hostname`
- Verifique credenciais SSH
- Verifique se SSH está habilitado nos hosts
- Verifique firewall e permissões de rede

### Erros de "Permission denied"

- Verifique se o usuário está correto
- Verifique se a senha está correta
- Verifique permissões de acesso no host

## 📄 Licença

Este script é fornecido como está, sem garantias.

## ✍️ Autor

Script de validação SSH para ambientes corporativos.

---

**Dica:** Para automação, você pode usar chaves SSH em vez de senhas. O `sshpass` é ideal para scripts interativos que precisam de autenticação por senha.
