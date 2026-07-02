#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK_STATS=false
HOSTS_FILE=""

for arg in "$@"; do
  case "$arg" in
    -s) DISK_STATS=true ;;
    *)  HOSTS_FILE="$arg" ;;
  esac
done

: "${HOSTS_FILE:=$SCRIPT_DIR/hosts.txt}"

if ! command -v sshpass >/dev/null 2>&1; then
  echo "Erro: 'sshpass' nao encontrado. Instale o pacote antes de executar este script." >&2
  exit 1
fi

if [[ ! -f "$HOSTS_FILE" ]]; then
  echo "Erro: lista de hosts nao encontrada em $HOSTS_FILE" >&2
  exit 1
fi

read -r -p "Usuario SSH: " SSH_USER
if [[ -z "${SSH_USER// }" ]]; then
  echo "Erro: usuario nao informado." >&2
  exit 1
fi

read -r -s -p "Senha SSH: " SSH_PASS
echo
if [[ -z "$SSH_PASS" ]]; then
  echo "Erro: senha nao informada." >&2
  exit 1
fi

while IFS= read -r host || [[ -n "$host" ]]; do
  host="${host%$'\r'}"

  # Ignora linhas em branco e comentarios.
  [[ -z "$host" || "$host" =~ ^[[:space:]]*# ]] && continue

  output="$(SSHPASS="$SSH_PASS" sshpass -e ssh -n \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=30 \
    -o NumberOfPasswordPrompts=1 \
    -o PreferredAuthentications=password \
    "$SSH_USER@$host" "$(if $DISK_STATS; then echo 'df -h /home/; '; fi)exit" 2>&1)"
  rc=$?

  if [[ $rc -eq 0 ]]; then
    if $DISK_STATS; then
      printf "%s\n" "$host"
      printf "%s\n" "$output"
      printf "\033[32mStatus: OK\033[0m\n\n"
    else
      printf "\033[32m%s - OK\033[0m\n" "$host"
    fi
  elif [[ "$output" =~ [Pp]ermission[[:space:]]denied|[Aa]ccess[[:space:]]denied ]]; then
    printf "\033[33m%s - Permission denied\033[0m\n" "$host"
  elif [[ "$output" =~ [Tt]imed[[:space:]]out|[Cc]onnection[[:space:]]timed[[:space:]]out ]]; then
    printf "\033[31m%s - Host unavailable\033[0m\n" "$host"
  else
    printf "\033[31m%s - Host unavailable\033[0m\n" "$host"
  fi
done < "$HOSTS_FILE"

unset SSH_PASS
