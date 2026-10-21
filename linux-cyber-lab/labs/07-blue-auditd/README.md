# Lab 07 — Auditoria com auditd

> 🔵 **Blue Team** · ⭐⭐⭐ Intermediário · ⏱️ ~30 min · 🏅 150 pontos
>
> Pré-requisito: `auditd` instalado. O `setup.sh` já tentou instalar as regras.

## 🎯 Objetivo

Log "normal" (`auth.log`, `syslog`) conta **quem entrou**. O `auditd` conta **o que foi feito** — inclusive o que não gera log de aplicação, como um `chmod 4755` ou a escrita em `/etc/cron.d`.

Neste lab você vai:

- validar as regras que já estão no host
- **provocar** eventos e encontrá-los por chave
- escrever **suas próprias regras** de detecção
- entender por que auditoria é a diferença entre "acho que fui invadido" e "sei o que aconteceu"

## 🧩 Cenário

Você assumiu o monitoramento do servidor do lab. O time pediu três alertas:

1. alguém criou ou alterou usuário
2. alguém mexeu em configuração de `sudo`
3. alguém colocou algo executável em `/tmp`

Sua tarefa é provar que esses três cenários **são detectáveis** com a configuração atual ou com regras novas.

## 📌 Tarefas

### Tarefa 1 — Estado do serviço

```bash
sudo systemctl status auditd --no-pager
sudo auditctl -s
sudo auditctl -l
```

**Entrega:** o serviço está ativo? Quantas regras estão carregadas? O campo `enabled` está `1`?

> Se `auditd` não estiver instalado:
> ```bash
> sudo apt update && sudo apt install -y auditd
> sudo systemctl enable --now auditd
> ```

---

### Tarefa 2 — Regras do laboratório

```bash
sudo auditctl -l | grep cyberlab
```

Esperado:

```
-w /etc/passwd -p wa -k cyberlab_identidade
-w /etc/shadow -p wa -k cyberlab_identidade
-w /etc/sudoers -p wa -k cyberlab_sudo
-w /etc/sudoers.d/ -p wa -k cyberlab_sudo
-w /etc/cron.d/ -p wa -k cyberlab_cron
-w /opt/cyberlab/scripts/ -p wa -k cyberlab_scripts
-w /root/.ssh/ -p wa -k cyberlab_ssh
```

**Entrega:** a lista e o significado de `-p wa` (write + attribute change).

---

### Tarefa 3 — Provocar e encontrar eventos

Execute os três eventos abaixo, **um de cada vez**, e encontre cada um no `ausearch`:

```bash
# 1) criação de usuário
sudo useradd lab07test

# 2) alteração em sudoers.d
echo "# lab07 - teste de auditoria" | sudo tee -a /etc/sudoers.d/cyberlab-labs

# 3) escrita no diretório do cron do lab
sudo touch /opt/cyberlab/scripts/lab07-teste.txt
```

Buscas:

```bash
sudo ausearch -k cyberlab_identidade -i | tail -30
sudo ausearch -k cyberlab_sudo -i | tail -20
sudo ausearch -k cyberlab_scripts -i | tail -20
```

**Entrega:** para **cada** evento, as 3 linhas mais relevantes (`type=SYSCALL`, `type=PATH`, `type=PROCTITLE`) e a identificação de:

- `comm` / `exe` → qual processo escreveu
- `auid` / `uid` → qual sessão de usuário
- `name` → qual arquivo

---

### Tarefa 4 — Escreva duas regras novas

Crie `/etc/audit/rules.d/cyberlab-lab07.rules` com:

**Regra A** — detectar a execução de `useradd`:

```
-a always,exit -F arch=b64 -S execve -F exe=/usr/sbin/useradd -k cyberlab_useradd
```

**Regra B** — detectar execução de qualquer coisa em `/tmp`:

```
-w /tmp -p x -k cyberlab_tmp_exec
```

Carregue e teste:

```bash
sudo augenrules --load
sudo auditctl -l | grep -E "cyberlab_useradd|cyberlab_tmp_exec"

sudo useradd lab07test2
sudo /bin/true            # gera execução normal, não deve casar com /tmp
cp /bin/true /tmp/lab07-exec && /tmp/lab07-exec

sudo ausearch -k cyberlab_useradd -i
sudo ausearch -k cyberlab_tmp_exec -i
```

**Entrega:** as duas regras + a prova de que dispararam.

---

### Tarefa 5 — Relatórios prontos

```bash
sudo aureport --auth --summary
sudo aureport -f --summary | head -20
sudo aureport --failed --summary
```

**Entrega:** uma linha de cada relatório que você usaria em um relatório de incidente.

---

### Tarefa 6 — `deteccoes.md`

Documente:

| Cenário | Regra | Chave | Comando de busca | Falso positivo |
| :-- | :-- | :-- | :-- | :-- |
| novo usuário | | | | |
| mudança em sudo | | | | |
| execução em /tmp | | | | |
| chave SSH no root | | | | |
| script de cron alterado | | | | |

**Entrega:** tabela preenchida + 1 parágrafo sobre o custo do `auditd` (volume de log / performance).

## 🧹 Limpeza

```bash
sudo userdel -r lab07test 2>/dev/null
sudo userdel -r lab07test2 2>/dev/null
sudo rm -f /opt/cyberlab/scripts/lab07-teste.txt /tmp/lab07-exec
sudo sed -i '/lab07 - teste/d' /etc/sudoers.d/cyberlab-labs 2>/dev/null
```

## 💡 Dicas

<details>
<summary>Dica 1 — auditd não está rodando</summary>

```bash
sudo systemctl enable --now auditd
sudo auditctl -s
```

Se `enabled` vier `0`, o kernel está com auditoria desligada (parâmetro `audit=0`). Em VM de lab, um reboot costuma resolver. Verifique:

```bash
cat /proc/cmdline
```

</details>

<details>
<summary>Dica 2 — nenhuma regra aparece em auditctl -l</summary>

As regras em `/etc/audit/rules.d/*.rules` só entram em vigor quando carregadas:

```bash
sudo augenrules --load
```

Se der erro de sintaxe, teste uma regra isolada:

```bash
sudo auditctl -w /etc/passwd -p wa -k teste
sudo auditctl -l | grep teste
```

</details>

<details>
<summary>Dica 3 — ausearch não acha nada</summary>

- a busca padrão é pelas últimas 24h; force período: `ausearch -k chave -ts today`
- confira se o evento realmente aconteceu: `sudo ausearch -m USER_ACCT -ts today`
- se você rodou `augenrules --load`, o evento anterior a isso pode estar com a chave antiga
- `-i` traduz IDs em nomes; sem ele os campos ficam numéricos

</details>

<details>
<summary>Dica 4 — interpretando o SYSCALL</summary>

```
type=SYSCALL msg=audit(1707874532.123:456): arch=c000003e syscall=257 success=yes
  exit=3 a0=ffffff9c ... items=1 ppid=1234 pid=5678 auid=1000 uid=0 gid=0 euid=0
  comm="tee" exe="/usr/bin/tee" key="cyberlab_sudo"
```

- `syscall=257` → `openat` (abertura de arquivo)
- `auid=1000` → sessão original do usuário (quem estava logado)
- `uid=0` → privilégio **no momento** da ação → `sudo` no meio
- `comm="tee" exe="/usr/bin/tee"` → o processo que escreveu
- `key="cyberlab_sudo"` → a regra que casou

`auid=1000` + `uid=0` é a assinatura de "usuário comum escalando".

</details>

<details>
<summary>Dica 5 — falso positivo é regra ruim</summary>

Exemplos que vão encher seu log sem indicar ataque:

- `passwd` alterando `/etc/shadow` em troca de senha legítima
- `apt`/`dpkg` criando usuários de pacote (`systemd-*`, `_apt`)
- backup lendo `/root/.ssh`
- `sudo` normal do administrador

Boa regra tem **contexto**: `auid`, horário, `exe`, `uid`. Só chave não basta.

</details>

## ✅ Critérios de conclusão

- [ ] `auditctl -l` com as 7 regras do lab
- [ ] Os 3 eventos provocados e encontrados com evidência
- [ ] 2 regras novas criadas, carregadas e testadas
- [ ] `deteccoes.md` completo
- [ ] Ambiente limpo

## 🧠 Perguntas

1. Por que `auditd` é mais confiável que `~/.bash_history` como evidência?
2. O que acontece com o log do `auditd` se o atacante obtém root? Como mitigar?
3. `-w /tmp -p x` gera muito ruído em servidor real. Como você reduziria isso?

---

<details>
<summary>🔓 Solução comentada (spoiler)</summary>

Veja [`solution.md`](solution.md).

</details>
