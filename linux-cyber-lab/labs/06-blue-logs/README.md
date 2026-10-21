# Lab 06 — Logs e relatório de incidente

> 🔵 **Blue Team** · ⭐⭐ Intermediário · ⏱️ ~40 min · 🏅 200 pontos
>
> Pré-requisito: nenhum. Os logs já estão em `/opt/cyberlab/logs`.

## 🎯 Objetivo

Você recebeu um pacote de logs de um servidor que **já foi comprometido**. Ninguém te disse o que aconteceu. Sua missão é reconstruir o incidente e escrever um relatório que qualquer gestor entenda.

Ao final você deve ter:

- `respostas.md` com as 10 perguntas respondidas e **evidência** (linha do log)
- `relatorio-incidente.md` preenchido a partir do template
- Uma timeline coerente, do primeiro scan até a exfiltração

## 🧩 Cenário

O host `kali` foi comprometido. O time de infraestrutura recuperou:

```
/opt/cyberlab/logs/auth.log              # autenticação (sshd, sudo, su, cron)
/opt/cyberlab/logs/access.log            # servidor web interno
/opt/cyberlab/logs/history-svc-backup.txt # histórico do usuário comprometido
/opt/cyberlab/logs/ps-snapshot.txt       # processos no momento da coleta
```

Você **não** tem o disco. Só os logs. Isso é proposital: a maioria das investigações reais começa assim.

## 📌 Perguntas

Crie `respostas.md` e responda **citando a linha exata** do log. Resposta sem evidência não conta.

1. Qual é o IP do atacante? Qual IP é legítimo e por quê?
2. Quantas tentativas de senha falharam antes do acesso bem-sucedido?
3. Qual usuário foi comprometido? Em que horário e com qual método de autenticação?
4. Liste, em ordem cronológica, as **ações pós-comprometimento** que aparecem no `auth.log`.
5. Quais técnicas de **persistência** o atacante usou? (cite o artefato de cada uma)
6. Qual ação de **anti-forense** foi executada?
7. O que foi **exfiltrado**? Cite a evidência no `auth.log` e no `access.log`.
8. Qual foi o **dwell time** aproximado (primeiro acesso válido até a última ação observada)?
9. O `access.log` mostra reconhecimento web. Quais caminhos foram testados e o que isso indica sobre o atacante?
10. Mapeie **5 eventos** para técnicas MITRE ATT&CK (formato `T____`).

## 📌 Entregáveis

### `respostas.md`

```markdown
## 1. IP do atacante
**Resposta:** ...
**Evidência:** `linha do log`
```

### `relatorio-incidente.md`

Copie o template:

```bash
cp docs/relatorio-incidente.md relatorio-incidente.md
```

Preencha as 9 seções. O resumo executivo deve ter no máximo 5 linhas e **não pode** conter termo técnico sem explicação.

## 💡 Dicas

<details>
<summary>Dica 1 — os comandos que resolvem 80%</summary>

```bash
cd /opt/cyberlab/logs

# quem falhou e quantas vezes
grep "Failed password" auth.log | awk '{print $11}' | sort | uniq -c | sort -rn

# quem entrou com sucesso
grep -E "Accepted (password|publickey)" auth.log

# o que o usuário comprometido fez
grep "sudo:" auth.log

# todo o log em ordem, com foco no atacante
grep "10.10.10.66" auth.log
```

</details>

<details>
<summary>Dica 2 — separando atacante de usuário legítimo</summary>

Compare os IPs. Um deles aparece **só** nas tentativas falhas e no acesso suspeito. O outro aparece em horários normais, com autenticação por chave e sem falhas.

```bash
awk '{print $11}' auth.log | sort | uniq -c | sort -rn | head
grep -c "10.10.10.66" auth.log
grep -c "192.168.0.15" auth.log
```

</details>

<details>
<summary>Dica 3 — contando tentativas corretamente</summary>

Cuidado com a diferença entre:

- `Failed password for invalid user admin` → tentativa falha para usuário **inexistente**
- `Invalid user oracle from ...` → apenas o registro de que alguém tentou um usuário inválido (não é uma tentativa de senha)
- `Failed password for svc-backup` → tentativa falha para usuário **existente**

Se a pergunta é "quantas tentativas de senha falharam", conte as linhas com `Failed password`.

```bash
grep -c "Failed password" auth.log
```

</details>

<details>
<summary>Dica 4 — lendo o access.log</summary>

Códigos de status:

- `200` = existe e foi entregue
- `201` = criado (upload!)
- `404` = não existe (mas revela **intenção**)

Um `GET /.env` com 404 continua sendo evidência de ataque: o atacante **tentou** ler segredo.

```bash
awk '{print $1}' access.log | sort | uniq -c
grep "10.10.10.66" access.log | grep -v " 404 "
```

</details>

<details>
<summary>Dica 5 — MITRE ATT&CK</summary>

Consulte <https://attack.mitre.org/>. Para este incidente, procure as táticas:

- Credential Access (força bruta)
- Persistence (conta local, chave SSH, cron)
- Privilege Escalation (SUID)
- Defense Evasion (limpar log)
- Exfiltration

Não precisa acertar o sub-técnica exata; o importante é justificar.

</details>

<details>
<summary>Dica 6 — escrevendo o resumo executivo</summary>

Errado:

> "O atacante usou SSH brute force e escalou via sudo, criou o usuário bkp e exfiltrô com curl."

Certo:

> "Um agente externo obteve acesso indevido a uma conta de serviço por tentativa de senhas e, com isso, criou acesso permanente e copiou dados de backup para fora da empresa. O acesso durou cerca de 13 minutos e foi contido após revisão dos registros de autenticação."

Sem jargão, com impacto e duração.

</details>

## ✅ Critérios de conclusão

- [ ] 10 respostas com evidência
- [ ] Timeline com pelo menos 8 eventos
- [ ] 5 técnicas MITRE com justificativa
- [ ] Relatório com recomendações priorizadas
- [ ] Nenhuma conclusão sem linha de log que sustente

## 🧠 Pergunta final

O `auth.log` mostra `rm -f /var/log/btmp`. Se o atacante tivesse feito `> /var/log/auth.log`, o que você **ainda** conseguiria provar? E o que perderia para sempre?

---

<details>
<summary>🔓 Solução comentada (spoiler)</summary>

Veja [`solution.md`](solution.md).

</details>
