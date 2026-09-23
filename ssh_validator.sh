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

# Classifica o percentual de uso de disco em uma faixa de status, imprimindo "status|cor_ansi".
classify_disk_status() {
  local pct="$1"
  if (( pct <= 60 )); then
    echo "OK|32"
  elif (( pct <= 80 )); then
    echo "Atencao|33"
  elif (( pct < 90 )); then
    echo "Critico|31"
  else
    echo "Emergencia|41"
  fi
}

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

      while IFS= read -r df_line; do
        [[ -z "$df_line" || "$df_line" =~ Use% ]] && continue
        use_pct="$(awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+%$/) print $i}' <<< "$df_line")"
        [[ -z "$use_pct" ]] && continue
        status_info="$(classify_disk_status "${use_pct%%%}")"
        printf "\033[%smStatus Armazenamento: %s (%s)\033[0m\n" "${status_info#*|}" "${status_info%%|*}" "$use_pct"
      done <<< "$output"

      printf "\033[32mStatus SSH: OK\033[0m\n\n"
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
