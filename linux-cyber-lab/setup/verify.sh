#!/usr/bin/env bash
#
# verify.sh - corretor automatico do hardening (lab 08)
#
# Uso:  sudo ./setup/verify.sh
# Saida: PASS/FAIL por item + pontuacao final (meta: 8/8)
#
set -uo pipefail

LAB_ROOT="/opt/cyberlab"
SRV_ROOT="/srv/cyberlab"

pass=0
fail=0
total=0

C_OK=$'\033[1;32m'
C_NO=$'\033[1;31m'
C_OFF=$'\033[0m'

report() {
  local nome=$1
  local status=$2   # ok | fail
  local detalhe=${3:-}
  total=$((total + 1))
  if [[ "$status" == "ok" ]]; then
    pass=$((pass + 1))
    printf '  %s[PASS]%s %s\n' "$C_OK" "$C_OFF" "$nome"
  else
    fail=$((fail + 1))
    printf '  %s[FAIL]%s %s\n' "$C_NO" "$C_OFF" "$nome"
    [[ -n "$detalhe" ]] && printf '         -> %s\n' "$detalhe"
  fi
}

echo
echo "=============================================="
echo "  VERIFICACAO DE HARDENING - LINUX CYBER LAB"
echo "=============================================="

if [[ $EUID -ne 0 ]]; then
  echo "  [i] Rodando sem root: alguns testes podem falhar sem motivo."
fi
echo

# 1. SUID indevido
suid=$(find "$LAB_ROOT" -perm -4000 -type f 2>/dev/null | wc -l)
if [[ "$suid" -eq 0 ]]; then
  report "Nenhum binario SUID em $LAB_ROOT" ok
else
  report "Nenhum binario SUID em $LAB_ROOT" fail \
    "$(find "$LAB_ROOT" -perm -4000 -type f 2>/dev/null | paste -sd' ' -)"
fi

# 2. Sudoers inseguro
if [[ -f /etc/sudoers.d/cyberlab-labs ]] && grep -q 'NOPASSWD' /etc/sudoers.d/cyberlab-labs 2>/dev/null; then
  report "Regra de sudo NOPASSWD removida" fail "/etc/sudoers.d/cyberlab-labs ainda tem NOPASSWD"
else
  report "Regra de sudo NOPASSWD removida" ok
fi

# 3. Arquivos gravaveis por todos
ww=$(find "$LAB_ROOT" "$SRV_ROOT" -perm -0002 -type f 2>/dev/null | wc -l)
if [[ "$ww" -eq 0 ]]; then
  report "Sem arquivos world-writable no lab" ok
else
  report "Sem arquivos world-writable no lab" fail \
    "$(find "$LAB_ROOT" "$SRV_ROOT" -perm -0002 -type f 2>/dev/null | paste -sd' ' -)"
fi

# 4. Script de cron
SCRIPT="$LAB_ROOT/scripts/maintenance.sh"
if [[ ! -e "$SCRIPT" ]]; then
  report "Script de manutencao restrito" ok "(arquivo removido)"
else
  mode=$(stat -c '%a' "$SCRIPT")
  owner=$(stat -c '%U' "$SCRIPT")
  if [[ "$mode" == "700" && "$owner" == "root" ]]; then
    report "Script de manutencao restrito" ok
  else
    report "Script de manutencao restrito" fail "modo=$mode dono=$owner (esperado 700 root)"
  fi
fi

# 5. Chave SSH
KEY="/home/dev01/.ssh/id_rsa"
if [[ ! -e "$KEY" ]]; then
  report "Chave SSH protegida ou removida" ok
else
  mode=$(stat -c '%a' "$KEY")
  if [[ "$mode" == "600" ]]; then
    report "Chave SSH protegida ou removida" ok
  else
    report "Chave SSH protegida ou removida" fail "modo=$mode (esperado 600)"
  fi
fi

# 6. Contas do lab bloqueadas/removidas
problema=""
for u in dev01 dev02; do
  if id "$u" &>/dev/null; then
    st=$(passwd -S "$u" 2>/dev/null | awk '{print $2}')
    [[ "$st" == "L" ]] || problema="$problema $u($st)"
  fi
done
if [[ -z "$problema" ]]; then
  report "Contas do lab bloqueadas ou removidas" ok
else
  report "Contas do lab bloqueadas ou removidas" fail "contas ativas:$problema (use: sudo passwd -l dev01)"
fi

# 7. Auditoria ativa
if command -v auditctl >/dev/null && auditctl -l 2>/dev/null | grep -q 'cyberlab'; then
  report "Regras de auditoria carregadas" ok
elif [[ -f /etc/audit/rules.d/cyberlab.rules ]] && command -v auditctl >/dev/null; then
  report "Regras de auditoria carregadas" fail "arquivo existe, mas nao carregado (sudo augenrules --load)"
else
  report "Regras de auditoria carregadas" fail "instale o auditd e carregue as regras"
fi

# 8. Flag3 restrita
if [[ ! -e /root/flag3.txt ]]; then
  report "Arquivo sensivel com permissao 600" ok "(arquivo removido)"
else
  mode=$(stat -c '%a' /root/flag3.txt)
  if [[ "$mode" == "600" ]]; then
    report "Arquivo sensivel com permissao 600" ok
  else
    report "Arquivo sensivel com permissao 600" fail "modo=$mode"
  fi
fi

echo
echo "----------------------------------------------"
if [[ "$fail" -eq 0 ]]; then
  printf '  RESULTADO: %s%d/%d - HARDENING COMPLETO %s\n' "$C_OK" "$pass" "$total" "$C_OFF"
else
  printf '  RESULTADO: %s%d/%d%s (%d pendente(s))\n' "$C_OK" "$pass" "$total" "$C_OFF" "$fail"
fi
echo "----------------------------------------------"
echo

[[ "$fail" -eq 0 ]] || exit 1
