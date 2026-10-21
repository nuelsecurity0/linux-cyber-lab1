# 🔓 Solução — Lab 04

> ⚠️ **Spoiler.** Tente antes de abrir.

## Red

### R1 — Cron

```bash
sudo tee /etc/cron.d/lab04-tarefa >/dev/null <<'EOF'
* * * * * root /bin/sh -c 'date >> /tmp/.lab04-cron'
EOF
sudo chmod 644 /etc/cron.d/lab04-tarefa
sudo chown root:root /etc/cron.d/lab04-tarefa
```

Prova:

```bash
sleep 70
cat /tmp/.lab04-cron
```

Por que funciona: qualquer arquivo em `/etc/cron.d` com dono `root` e modo `644` é lido pelo daemon. O nome não pode ter ponto.

### R2 — systemd

```bash
sudo tee /etc/systemd/system/lab04.service >/dev/null <<'EOF'
[Unit]
Description=Lab04 persistence

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'date >> /tmp/.lab04-systemd'
EOF

sudo tee /etc/systemd/system/lab04.timer >/dev/null <<'EOF'
[Unit]
Description=Lab04 timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now lab04.timer
systemctl list-timers --all | grep lab04
```

Prova:

```bash
cat /tmp/.lab04-systemd
```

Por que é stealth: a unit fica em `/etc/systemd/system` e o serviço só aparece em `ps` por milissegundos (é `Type=oneshot`).

### R3 — Chave SSH

```bash
ssh-keygen -t ed25519 -f /tmp/lab04_key -N "" -C "lab04" -q
sudo mkdir -p /root/.ssh && sudo chmod 700 /root/.ssh
sudo tee -a /root/.ssh/authorized_keys < /tmp/lab04_key.pub
sudo chmod 600 /root/.ssh/authorized_keys
```

Prova:

```bash
sudo grep lab04 /root/.ssh/authorized_keys
```

Por que funciona: autenticação por chave **não passa** por senha. Trocar a senha do root não invalida a chave.

## Blue

### B1 — Cron

```bash
sudo find /etc/cron* /var/spool/cron -mmin -120 -type f 2>/dev/null
sudo ls -la /etc/cron.d/
```

Achado esperado:

```
/etc/cron.d/lab04-tarefa
```

Verificação rápida de qualquer arquivo suspeito:

```bash
sudo cat /etc/cron.d/lab04-tarefa
sudo stat -c '%U %a %y' /etc/cron.d/lab04-tarefa
```

Sinais de alerta:

- comando com `curl`, `wget`, `base64`, `bash -c`
- caminho em `/tmp` ou `/dev/shm`
- nome genérico (`update`, `sync`, `cache`) sem relação com o serviço
- data de modificação recente em host estável

### B2 — systemd

```bash
systemctl list-timers --all
sudo find /etc/systemd/system -name "*.service" -mmin -120
sudo systemctl cat lab04.service
```

Em 30 segundos, o que olhar:

1. `ExecStart` aponta para binário de sistema (`/usr/sbin/nginx`) ou para `/bin/sh -c '...'`?
2. a unit tem `Documentation=` e descrição coerente com o host?
3. o nome segue o padrão do pacote (`nginx.service`) ou é genérico (`lab04`, `update`)?
4. `Created by` no `systemctl cat` (quando existe) aponta para um pacote `apt`?

### B3 — auditd

```bash
sudo ausearch -k cyberlab_cron -i
```

Evento esperado (resumido):

```
type=SYSCALL ... syscall=openat ... comm="tee" exe="/usr/bin/tee" key="cyberlab_cron"
type=PATH ... name="/etc/cron.d/lab04-tarefa" ...
```

```bash
sudo ausearch -k cyberlab_ssh -i
```

```
type=SYSCALL ... comm="tee" exe="/usr/bin/tee" key="cyberlab_ssh"
type=PATH ... name="/root/.ssh/authorized_keys"
```

O campo decisivo é `comm`/`exe` (quem escreveu) combinado com `auid` (sessão original). `auid=1000`, `uid=0` = usuário comum usando `sudo`.

### B4 — Documento

| Técnica | Artefato | Como detectar | Regra de auditoria | Falso positivo |
| :-- | :-- | :-- | :-- | :-- |
| cron | `/etc/cron.d/*`, `/var/spool/cron/*` | `find -mmin`, diff de baseline | `-w /etc/cron.d/ -p wa -k cyberlab_cron` | deploy de aplicação que instala cron |
| systemd | `/etc/systemd/system/*.service/.timer` | `systemctl list-timers`, `cat` da unit | `-w /etc/systemd/system/ -p wa -k systemd` | atualização de pacote |
| SSH key | `/root/.ssh/authorized_keys` | diff + `auditd` | `-w /root/.ssh/ -p wa -k cyberlab_ssh` | automação/Ansible legítimo |

## Limpeza

```bash
sudo rm -f /etc/cron.d/lab04-tarefa /tmp/.lab04-cron
sudo systemctl disable --now lab04.timer
sudo rm -f /etc/systemd/system/lab04.{service,timer}
sudo systemctl daemon-reload
sudo sed -i '/lab04/d' /root/.ssh/authorized_keys
rm -f /tmp/lab04_key /tmp/lab04_key.pub /tmp/.lab04-systemd
```

## Lições

1. Persistência é **redundante** por natureza. Quem planta uma, planta três.
2. O que não muda nunca é suspeito em um host que não muda nunca — e o que muda sem motivo é suspeito em qualquer host.
3. `authorized_keys` é o "backdoor educado": não precisa de malware, não aparece em `ps`, não quebra no reboot.
4. Detecção boa é **baseline + diff**, não `grep` de palavra-chave.
