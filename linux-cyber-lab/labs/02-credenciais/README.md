# Lab 02 — Caça a credenciais

> 🔴 **Red Team** · ⭐⭐ Intermediário · ⏱️ ~30 min · 🏅 150 pontos
>
> Pré-requisito: Lab 01 concluído e sessão como `dev01`.

## 🎯 Objetivo

Credencial esquecida é a forma mais comum de comprometer um host — muito mais do que exploit de kernel. Neste lab você vai procurar **senhas, chaves e segredos** deixados por descuido e usar isso para **movimento lateral**.

Ao final você deve ter:

- 3 segredos diferentes encontrados (histórico, `.env`, script de backup)
- 1 chave SSH analisada
- Acesso ao usuário `dev02` e a **flag 2**

## 🧩 Cenário

O `dev01` é um desenvolvedor que saiu da empresa. A conta dele continua ativa e o histórico de shell nunca foi limpo. Você tem a senha dele (faz parte do cenário) e agora quer chegar mais longe.

```bash
su - dev01      # senha: V4mosLab!01
```

## 📌 Tarefas

### Tarefa 1 — Histórico de shell

O arquivo `~/.bash_history` guarda comandos digitados. Muita gente digita senha na linha de comando.

```bash
cat ~/.bash_history
```

**Entrega:**

- 2 credenciais encontradas
- a diferença entre uma senha "real" e um decoy (dica: teste, não confie)

---

### Tarefa 2 — Segredos em arquivos de configuração

Procure em `~/projetos`:

```bash
find ~/projetos -type f | head -50
cat ~/projetos/api/.env
```

O valor de `DB_PASS` está em **Base64**. Isso **não é criptografia**.

```bash
echo "VALOR" | base64 -d ; echo
```

**Entrega:** senha decodificada e o comando usado.

---

### Tarefa 3 — Credencial em script de backup

Explore `/srv/cyberlab/backup`:

```bash
ls -la /srv/cyberlab/backup
cat /srv/cyberlab/backup/backup.sh
```

**Entrega:** a variável de ambiente exportada no script e por que isso é um problema.

---

### Tarefa 4 — Analise a chave SSH

```bash
ls -l ~/.ssh/
```

**Entrega:**

- permissão atual de `id_rsa` e o que deveria ser (`600`)
- a chave tem passphrase? Prove com:

```bash
ssh-keygen -y -f ~/.ssh/id_rsa >/dev/null && echo "SEM passphrase"
```

- risco concreto de uma chave sem passphrase com permissão `644`

---

### Tarefa 5 — Movimento lateral e flag 2

Use o que encontrou para virar `dev02`:

```bash
su - dev02
cat ~/flag2.txt
```

**Entrega:** a flag 2 e o caminho completo (qual segredo você usou).

---

## 💡 Dicas

<details>
<summary>Dica 1 — onde olhar primeiro</summary>

Comece pelo óbvio. Histórico de shell, arquivos `.env`, `.git/config`, `config.php`, `backup.sh`, `docker-compose.yml`, notas em `~/Documentos`.

```bash
ls -la ~
ls -la ~/projetos
```

</details>

<details>
<summary>Dica 2 — ler o histórico com contexto</summary>

O `grep` ajuda a filtrar:

```bash
grep -iE "pass|senha|pwd|secret|token|su |ssh" ~/.bash_history
```

Leia as linhas em volta — o contexto costuma dizer **de quem** é a senha.

</details>

<details>
<summary>Dica 3 — Base64</summary>

Base64 não esconde nada, só codifica:

```bash
echo "UzNuaDQtREItMjAyNA==" | base64 -d ; echo
# S3nh4-DB-2024
```

Se o valor tiver caracteres estranhos, confirme o encoding:

```bash
echo "..." | base64 -d | file -
```

</details>

<details>
<summary>Dica 4 — qual senha abre o dev02</summary>

No histórico do `dev01` existe uma linha comentada com a senha do `dev02`. É a única que funciona nesse host — a outra parece real, mas o banco não está rodando localmente.

</details>

## ✅ Critérios de conclusão

- [ ] 3 segredos documentados em `credenciais.md` (sem colar as senhas completas no relatório público — use máscara)
- [ ] Chave SSH analisada (permissão + passphrase)
- [ ] `dev02` acessado e flag 2 em `flags.md`

## 🧠 Para o Blue Team

1. Por que `.bash_history` com credenciais é um incidente, e não só "falta de higiene"?
2. Que permissão deveria ter `id_rsa` e o diretório `~/.ssh`?
3. Como detectar movimento lateral via `su` nos logs? (Você vai responder isso no lab 06.)

---

<details>
<summary>🔓 Solução comentada (spoiler)</summary>

Veja [`solution.md`](solution.md).

</details>
