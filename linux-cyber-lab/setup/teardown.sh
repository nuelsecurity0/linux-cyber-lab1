#!/usr/bin/env bash
#
# teardown.sh - remove tudo que o Linux Cyber Lab criou
#
# Uso: sudo ./setup/teardown.sh
#
set -uo pipefail

LAB_ROOT="/opt/cyberlab"
SRV_ROOT="/srv/cyberlab"

ok()   { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
info() { printf '\033[1;34m[i]\033[0m %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "Execute como root: sudo ./setup/teardown.sh"; exit 1; }

info "Removendo o Linux Cyber Lab..."

# Encerra sessoes dos usuarios do lab antes de apagar as contas
for u in dev01 dev02 svc-backup; do
  if id "$u" &>/dev/null; then
    pkill -KILL -u "$u" 2>/dev/null
    userdel -r -f "$u" 2>/dev/null && ok "usuario '$u' removido" || warn "nao consegui remover '$u'"
  fi
done

# Artefatos de ataque que os alunos costumam deixar para tras
rm -f /tmp/rootbash /tmp/.systemd-update /tmp/.cache.tar.gz /tmp/rootbash-* 2>/dev/null

# Configuracoes
rm -f /etc/sudoers.d/cyberlab-labs && ok "regra de sudoers removida"
rm -f /etc/cron.d/cyberlab-maintenance && ok "cron removido"
rm -f /root/flag3.txt

if [[ -f /etc/audit/rules.d/cyberlab.rules ]]; then
  rm -f /etc/audit/rules.d/cyberlab.rules
  command -v augenrules >/dev/null && augenrules --load >/dev/null 2>&1
  ok "regras de auditoria removidas"
fi

# Diretorios
rm -rf "$LAB_ROOT" && ok "removido $LAB_ROOT"
rm -rf "$SRV_ROOT" && ok "removido $SRV_ROOT"

echo
printf '\033[1;32m[+]\033[0m Laboratorio removido. A VM voltou ao estado anterior.\n'
