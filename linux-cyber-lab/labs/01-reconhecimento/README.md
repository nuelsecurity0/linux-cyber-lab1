# Lab 01 — Reconhecimento local

> 🔴 **Red Team** · ⭐ Iniciante · ⏱️ ~20 min · 🏅 100 pontos
>
> Pré-requisito: `sudo ./setup/setup.sh` já executado.

## 🎯 Objetivo

Antes de explorar qualquer falha, você precisa **saber o que existe no host**. Este lab treina a enumeração manual — sem `nmap`, sem `linpeas`, só comandos básicos e curiosidade.

Ao final você deve conseguir responder, sem abrir nenhum arquivo de solução:

- Qual é o host e o kernel?
- Quantas contas humanas existem e quais são elas?
- O que está escutando em portas de rede?
- Existe algum binário com **SUID** fora dos diretórios do sistema?
- Onde está a **flag 1**?

## 🧩 Cenário

Você acabou de ganhar acesso a um servidor Linux de um laboratório. É uma conta comum (`dev01`), sem root. O administrador anterior saiu da empresa às pressas e deixou o servidor "como estava".

Você não tem senha de root. Ainda.

## 📌 Tarefas

Crie um arquivo `recon.md` na raiz do repositório e registre tudo nele.

### Tarefa 1 — Identidade do host

Descubra:

- hostname e distribuição
- versão do kernel
- tempo de atividade (`uptime`)

```bash
hostnamectl
uname -a
uptime
```

**Entrega:** as três primeiras linhas de cada comando.

---

### Tarefa 2 — Quem existe neste host

Liste:

- todas as contas com shell válido (`/bin/bash`, `/bin/sh`, `/bin/zsh`)
- quais delas têm UID ≥ 1000 (contas humanas)
- quais são contas de serviço (normalmente UID < 1000 ou shell `nologin`)

```bash
cat /etc/passwd
awk -F: '$3 >= 1000 {print $1, $3, $7}' /etc/passwd
```

**Entrega:** tabela `usuário | UID | shell`.

> 💡 Conta de serviço com shell válido é bandeira vermelha: ela pode ser usada para login.

---

### Tarefa 3 — Superfície de rede

Veja o que está escutando:

```bash
ss -tulpn
```

**Entrega:** portas abertas, protocolo (TCP/UDP), processo e se escuta em `0.0.0.0` (todas as interfaces) ou apenas `127.0.0.1`.

> 🔎 Pergunta: uma porta em `127.0.0.1` é inacessível de fora. Isso é bom ou ruim para o atacante que já está dentro?

---

### Tarefa 4 — Binários SUID

SUID faz um programa rodar com o privilégio do dono. Se o dono é `root`, o programa roda como root.

```bash
find / -perm -4000 -type f 2>/dev/null
```

**Entrega:**

- a lista completa
- **destaque** os que estão fora de `/usr/bin`, `/usr/sbin`, `/bin`, `/sbin`
- para o que chamou atenção, descubra o que ele faz (`man`, `--help`)

> ⚠️ Não execute nada ainda. Este lab é só reconhecimento.

---

### Tarefa 5 — Arquivos graváveis por todos

```bash
find / -perm -0002 -type f 2>/dev/null
find / -writable -type d 2>/dev/null
```

**Entrega:** os arquivos/diretórios que **não** são de sistema (`/tmp`, `/var/tmp`, `/dev/shm` são esperados).

---

### Tarefa 6 — Encontre a flag 1

A flag está em algum lugar do host, no formato `FLAG{...}`. Você **não** sabe o caminho.

**Entrega:** o conteúdo da flag e o comando exato que usou para encontrá-la.

---

## 💡 Dicas

<details>
<summary>Dica 1 — por onde começar a procurar a flag</summary>

Você não precisa varrer o disco inteiro procurando nomes. Procure pelo **conteúdo**: a flag sempre começa com `FLAG{`.

```bash
grep -r "FLAG{" / 2>/dev/null
```

Vai demorar e vai gerar muito ruído. Filtre por diretórios plausíveis primeiro: `/opt`, `/home`, `/srv`, `/var`.

</details>

<details>
<summary>Dica 2 — o diretório do laboratório</summary>

Tudo que o setup criou está em `/opt/cyberlab`. Comece por lá:

```bash
ls -la /opt/cyberlab
ls -laR /opt/cyberlab
```

Arquivos e diretórios que começam com `.` são **ocultos** — só aparecem com `ls -la`.

</details>

<details>
<summary>Dica 3 — dica direta para a flag 1</summary>

```bash
grep -rn "FLAG{" /opt/cyberlab 2>/dev/null
```

Depois de achar, tente explicar: **por que** o arquivo estava legível para o seu usuário?

</details>

<details>
<summary>Dica 4 — SUID fora do padrão</summary>

Compare a saída de `find / -perm -4000 -type f 2>/dev/null` com a lista esperada do sistema:

```bash
find / -perm -4000 -type f 2>/dev/null | grep -v -E '^/(usr/)?s?bin/'
```

Esse filtro mostra justamente o que **não** deveria estar ali.

</details>

## ✅ Critérios de conclusão

- [ ] `recon.md` criado com as 6 tarefas
- [ ] Flag 1 encontrada e registrada em `flags.md`
- [ ] Você sabe explicar o que é SUID **com suas palavras**

## 🧠 Perguntas para levar para o relatório (Blue Team)

1. Um SUID em `/opt` é mais ou menos perigoso que um SUID em `/usr/bin`? Por quê?
2. O que um analista deveria monitorar para detectar um novo arquivo SUID?
3. Se você fosse o administrador, qual seria a **primeira** correção a fazer?

---

<details>
<summary>🔓 Solução comentada (spoiler)</summary>

Veja [`solution.md`](solution.md) — só depois de tentar.

</details>
