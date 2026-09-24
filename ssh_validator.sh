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
    "$SSH_USER@$host" "$(if $DISK_STATS; then echo 'uptime; df -h /home/; '; fi)exit" 2>&1)"
  rc=$?

  # Remove o aviso do ssh sobre known_hosts, que nao interessa ao usuario.
  output="$(grep -v "^Warning: Permanently added" <<< "$output")"

  if [[ $rc -eq 0 ]]; then
    if $DISK_STATS; then
      printf "%s\n" "$host"
      printf "Status SSH: \033[32mOK\033[0m\n"

      uptime_info="$(sed -n '1p' <<< "$output")"
      printf "Status Uptime: %s\n" "$uptime_info"
      disk_output="$(awk '/^Filesystem[[:space:]]/{found=1} found' <<< "$output")"

      while IFS= read -r df_line; do
        [[ -z "$df_line" || "$df_line" =~ Use% ]] && continue
        use_pct="$(awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+%$/) print $i}' <<< "$df_line")"
        [[ -z "$use_pct" ]] && continue
        status_info="$(classify_disk_status "${use_pct%%%}")"
        printf "Status Armazenamento: \033[%sm%s (%s)\033[0m\n" "${status_info#*|}" "${status_info%%|*}" "$use_pct"
      done <<< "$disk_output"

      printf "%s\n\n" "$disk_output"
    else
      printf "%s - \033[32mOK\033[0m\n" "$host"
    fi
  elif [[ "$output" =~ [Pp]ermission[[:space:]]denied|[Aa]ccess[[:space:]]denied ]]; then
    printf "%s - \033[33mPermission denied\033[0m\n" "$host"
  elif [[ "$output" =~ [Tt]imed[[:space:]]out|[Cc]onnection[[:space:]]timed[[:space:]]out ]]; then
    printf "%s - \033[31mHost unavailable\033[0m\n" "$host"
  else
    printf "%s - \033[31mHost unavailable\033[0m\n" "$host"
  fi
done < "$HOSTS_FILE"

unset SSH_PASS
