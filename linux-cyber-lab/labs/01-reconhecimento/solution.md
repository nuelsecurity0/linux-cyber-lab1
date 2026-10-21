# 🔓 Solução — Lab 01

> ⚠️ **Spoiler.** Tente o lab inteiro antes de abrir.

## Tarefa 1 — Identidade

```bash
hostnamectl
# Static hostname: kali
# Operating System: Kali GNU/Linux Rolling
# Kernel: Linux 6.x ...

uname -a
uptime
```

O esperado é um Kali recente, kernel 6.x, com pouco tempo de atividade (VM recém-ligada).

## Tarefa 2 — Contas

```bash
awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1, $3, $7}' /etc/passwd
```

Resultado esperado inclui:

| usuário | UID | shell |
| :-- | :-- | :-- |
| root | 0 | /bin/bash |
| kali | 1000 | /bin/zsh ou /bin/bash |
| dev01 | 1001 | /bin/bash |
| dev02 | 1002 | /bin/bash |
| svc-backup | 1003 | /bin/bash |

Ponto de atenção: **`svc-backup` é conta de serviço com shell de login**. Contas de serviço deveriam ter `/usr/sbin/nologin`.

## Tarefa 3 — Rede

```bash
ss -tulpn
```

Em uma Kali padrão você verá coisas como:

```
tcp  LISTEN 0.0.0.0:22     0.0.0.0:*  users:(("sshd",pid=...))
```

Se houver serviço escutando em `0.0.0.0` que você não reconhece, esse é o próximo alvo.
Portas em `127.0.0.1` só são alcançáveis de dentro do host — mas um atacante com shell **já está dentro**, então elas também contam.

## Tarefa 4 — SUID

```bash
find / -perm -4000 -type f 2>/dev/null
```

Lista esperada (varia um pouco entre versões do Kali): `sudo`, `su`, `passwd`, `mount`, `umount`, `chsh`, `newgrp`, `pkexec`, `fusermount3`...

O que **não** pertence ao sistema:

```
/opt/cyberlab/bin/.cache-helper
```

```bash
ls -l /opt/cyberlab/bin/.cache-helper
# -rwsr-xr-x 1 root root ... .cache-helper

file /opt/cyberlab/bin/.cache-helper
# ELF 64-bit ... (é uma cópia do find)
```

Comando que mostra só as anomalias:

```bash
find / -perm -4000 -type f 2>/dev/null | grep -v -E '^/(usr/)?s?bin/'
```

> Não explore ainda. Isso é o lab 03.

## Tarefa 5 — World-writable

```bash
find /opt/cyberlab /srv/cyberlab -perm -0002 -type f 2>/dev/null
```

Esperado:

```
/opt/cyberlab/scripts/maintenance.sh
```

```bash
ls -l /opt/cyberlab/scripts/maintenance.sh
# -rwxrwxrwx 1 root root ... maintenance.sh
```

Esse script é executado como **root** por um cron a cada 2 minutos. Um arquivo `777` controlado por root é grave justamente por isso.

## Tarefa 6 — Flag 1

```bash
grep -rn "FLAG{" /opt/cyberlab 2>/dev/null
```

Ou:

```bash
find /opt/cyberlab -type f -name "*flag*"
cat /opt/cyberlab/data/.old-backups/flag1.txt
```

Resultado:

```
FLAG{r3c0n_3_4_b4s3_d3_tud0}
```

**Por que estava legível?** O arquivo tinha modo `0644` (todos podem ler) e o diretório `.old-backups` tinha `0755`. Um backup antigo esquecido é um dos vazamentos mais comuns em ambientes reais.

## Lições

1. Enumeração não é "rodar scanner": é entender o que é **normal** para detectar o **anormal**.
2. Nome de arquivo não é segurança. `.old-backups` esconde de `ls` sem `-a`, mas não de `find`/`grep`.
3. SUID + script gravável por todos + cron como root = três caminhos de escalada no mesmo host.
