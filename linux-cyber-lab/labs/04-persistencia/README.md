# Lab 04 — Persistência e detecção

> 🔴🔵 **Red + Blue (Purple)** · ⭐⭐⭐ Intermediário · ⏱️ ~40 min · 🏅 200 pontos
>
> Pré-requisito: root obtido no lab 03 (ou `sudo -i` a partir do `kali`).

## 🎯 Objetivo

Invadir é fácil. **Continuar dentro** depois de um reboot, de uma troca de senha ou de uma limpeza de logs é o que define um intruso persistente — e é o que o Blue Team precisa detectar.

Neste lab você vai:

1. plantar **duas** técnicas de persistência (Red)
2. caçar as duas com comandos de forense (Blue)
3. escrever como cada uma seria detectada em produção

É o lab mais "purple" do repositório: você é o atacante e o analista na mesma sessão.

## 🧩 Cenário

Você conseguiu root. Agora quer garantir acesso caso a senha do `svc-backup` seja trocada. O host é monitorado? Você **acha** que não. Vamos descobrir.

> ⚠️ Faça isso **somente na VM do lab**. Persistência em máquina real é crime, mesmo "só testando".

## 📌 Tarefas — Red

### Tarefa R1 — Persistência via cron

Crie um agendamento que execute um comando seu como root a cada minuto.

Requisitos:

- usar `/etc/cron.d/` (arquivo novo, não editar o do lab)
- executar algo **inofensivo e observável** (ex.: escrever data em `/tmp/.lab04-cron`)
- o nome do arquivo **não pode conter ponto** (o cron ignora nomes com `.`)

**Entrega:** caminho do arquivo, conteúdo e prova de que rodou.

---

### Tarefa R2 — Persistência via systemd

Crie um `service` + `timer` que rode algo no boot e a cada 5 minutos.

```bash
systemctl list-timers --all
```

**Entrega:** nome das units, conteúdo dos arquivos e saída de `systemctl list-timers`.

---

### Tarefa R3 — Persistência via chave SSH

Adicione uma chave sua ao `authorized_keys` do root.

```bash
ls -la /root/.ssh/
```

**Entrega:** o que você adicionou e como isso sobrevive a troca de senha.

---

## 📌 Tarefas — Blue

### Tarefa B1 — Caçar cron

Sem olhar suas anotações: encontre **todos** os agendamentos criados ou modificados nas últimas 2 horas.

```bash
sudo find /etc/cron* /var/spool/cron -mmin -120 -type f 2>/dev/null
sudo ls -la /etc/cron.d/
```

**Entrega:** comando + saída.

---

### Tarefa B2 — Caçar systemd

```bash
systemctl list-timers --all
systemctl list-units --type=service --state=running | grep -v -E "systemd|dbus|cron|ssh"
sudo find /etc/systemd/system -name "*.service" -mmin -120
```

**Entrega:** como você diferenciaria uma unit legítima de uma maliciosa em 30 segundos.

---

### Tarefa B3 — Caçar via auditd

As regras do lab já monitoram `/etc/cron.d/` e `/root/.ssh/`.

```bash
sudo ausearch -k cyberlab_cron -i
sudo ausearch -k cyberlab_ssh -i
```

**Entrega:** 1 evento encontrado (cole as linhas principais) e o campo que identifica o processo responsável.

> Se o `auditd` não estiver ativo, faça o lab 07 primeiro e volte aqui.

---

### Tarefa B4 — Documento de persistência

Crie `persistencia.md`:

| Técnica | Artefato | Como detectar | Regra de auditoria | Falso positivo comum |
| :-- | :-- | :-- | :-- | :-- |
| cron | | | | |
| systemd | | | | |
| SSH key | | | | |

---

## 🧹 Limpeza (obrigatória)

```bash
sudo rm -f /etc/cron.d/lab04-* /tmp/.lab04-cron
sudo systemctl disable --now lab04.timer lab04.service 2>/dev/null
sudo rm -f /etc/systemd/system/lab04.service /etc/systemd/system/lab04.timer
sudo systemctl daemon-reload
# remova a chave que você adicionou de /root/.ssh/authorized_keys
```

Se algo der errado: `sudo ./setup/reset.sh`.

## 💡 Dicas

<details>
<summary>Dica 1 — cron: o nome importa</summary>

O `run-parts`, usado pelo cron do Debian/Kali, **ignora** arquivos com ponto no nome. Então:

- ✅ `/etc/cron.d/lab04-tarefa`
- ❌ `/etc/cron.d/lab04.tarefa`

O arquivo precisa de 6 campos antes do comando:

```
* * * * * root /caminho/do/comando
```

E de permissão `644`, dono `root`.

</details>

<details>
<summary>Dica 2 — systemd: service + timer</summary>

`/etc/systemd/system/lab04.service`:

```ini
[Unit]
Description=Lab04

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'date >> /tmp/.lab04-systemd'
```

`/etc/systemd/system/lab04.timer`:

```ini
[Unit]
Description=Lab04 timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now lab04.timer
systemctl list-timers --all | grep lab04
```

</details>

<details>
<summary>Dica 3 — chave SSH no root</summary>

Gere um par de chaves **dentro da VM** (não use a sua chave pessoal!):

```bash
ssh-keygen -t ed25519 -f /tmp/lab04_key -N "" -C "lab04"
sudo mkdir -p /root/.ssh && sudo chmod 700 /root/.ssh
sudo tee -a /root/.ssh/authorized_keys < /tmp/lab04_key.pub
```

A chave pública em `authorized_keys` sobrevive a mudança de senha, mas **não** a remoção do arquivo. É por isso que o Blue Team procura exatamente ali.

</details>

<details>
<summary>Dica 4 — o que o auditd mostra</summary>

`ausearch -k cyberlab_ssh -i` deve mostrar algo como:

```
type=SYSCALL ... syscall=openat ... comm="tee" exe="/usr/bin/tee" key="cyberlab_ssh"
```

O campo `comm=` é o processo que escreveu. `exe=` é o binário. `auid=`/`uid=` diz **quem** estava logado — se for `auid=1000` e `uid=0`, você achou um `sudo`.

</details>

<details>
<summary>Dica 5 — detecção que funciona de verdade</summary>

Procurar por `-mmin -120` só funciona em laboratório. Em produção você compara com uma **linha de base**:

```bash
# gere uma vez, com o host limpo
sudo find /etc/cron* /etc/systemd/system -type f -exec sha256sum {} + | sort -k2 > baseline.txt

# depois, compare
sudo find /etc/cron* /etc/systemd/system -type f -exec sha256sum {} + | sort -k2 | diff baseline.txt -
```

</details>

## ✅ Critérios de conclusão

- [ ] 2 persistências plantadas e comprovadas
- [ ] 2 persistências encontradas como analista
- [ ] `persistencia.md` preenchido
- [ ] Ambiente limpo (ou declarado no documento)

## 🧠 Perguntas

1. Qual das três técnicas é a mais difícil de detectar? Por quê?
2. Por que `authorized_keys` é um alvo tão comum de Red Team?
3. Que alerta você criaria para "novo arquivo em `/etc/cron.d/`"?

---

<details>
<summary>🔓 Solução comentada (spoiler)</summary>

Veja [`solution.md`](solution.md).

</details>
