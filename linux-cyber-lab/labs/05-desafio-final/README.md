# Lab 05 — Desafio final cronometrado

> 🔴 **Red Team** · ⭐⭐⭐ Intermediário · ⏱️ **45 min** · 🏅 300 pontos
>
> Pré-requisito: labs 01–04 concluídos. **Rode `sudo ./setup/reset.sh` antes de começar** para ter um alvo limpo.

## 🎯 Objetivo

Executar a cadeia completa — **reconhecimento → credencial → movimento lateral → root** — sem consultar as soluções, dentro do tempo.

Este lab simula um teste real: você recebe um host, um prazo e precisa entregar evidência organizada.

## 🧩 Cenário

Um servidor Linux foi entregue para auditoria. Você tem apenas:

- o IP/host da VM
- uma conta de desenvolvedor: `dev01` / `V4mosLab!01`
- 45 minutos

Sua missão: provar acesso root e documentar o caminho.

## 📌 Regras

1. **Sem abrir** `solution.md` dos outros labs.
2. **Sem `linpeas`/`LinEnum`** no início. Você pode usar no final para conferir se deixou algo passar.
3. Cronômetro ligado. Anote o horário de início.
4. Se travar 10 minutos em uma etapa, registre o bloqueio e siga por outro caminho — faz parte do exercício.

## 📌 Entregáveis

### 1. `flags.txt`

```text
FLAG 1: 
FLAG 2: 
FLAG 3: 
inicio: HH:MM
root:   HH:MM
tempo total: XX min
```

### 2. `ataque.md`

Para **cada** etapa, registre:

| Etapa | Comando | Evidência (saída) | O que revelou |
| :-- | :-- | :-- | :-- |
| Recon | | | |
| Credencial | | | |
| Movimento lateral | | | |
| Escalada | | | |

### 3. `deteccao.md`

Para cada etapa do seu próprio ataque, responda:

- **Qual log/artefato** guarda esse passo?
- **Qual comando** um analista usaria para encontrá-lo?
- Isso seria detectado **hoje**, nesta VM, com a configuração padrão? (Sim/Não)

> Essa é a parte que separa "script kiddie" de profissional. Vale 100 dos 300 pontos.

### 4. `hardening.md`

Liste **5 correções** que teriam impedido seu ataque. Uma linha cada, no formato:

```
[etapa bloqueada] correção -> comando
```

## 🏅 Pontuação

| Item | Pontos |
| :-- | --: |
| Flag 1 | 40 |
| Flag 2 | 60 |
| Flag 3 (root) | 80 |
| `ataque.md` completo | 60 |
| `deteccao.md` com os 4 passos | 40 |
| `hardening.md` com 5 ações úteis | 20 |
| **Total** | **300** |
| Bônus: concluir em < 25 min | +30 |

## 💡 Dicas (use com moderação — o objetivo é não precisar)

<details>
<summary>Dica 1 — está travado no começo?</summary>

Você tem uma conta. O que uma conta comum consegue ver?

```bash
id
sudo -l
ls -la ~
cat ~/.bash_history
find / -perm -4000 -type f 2>/dev/null
```

Uma dessas cinco linhas destrava o lab inteiro.

</details>

<details>
<summary>Dica 2 — está travado na credencial?</summary>

O histórico do `dev01` tem **duas** senhas. Uma é isca, a outra abre o `dev02`. Leia com atenção o comentário da linha.

</details>

<details>
<summary>Dica 3 — está travado na escalada?</summary>

Existem três caminhos. Se um não funcionar, os outros dois continuam de pé:

- `sudo -l`
- SUID em `/opt/cyberlab/bin`
- cron a cada 2 minutos

</details>

<details>
<summary>Dica 4 — quer conferir depois</summary>

Rode `linpeas.sh` (baixe só se tiver internet) e compare com o que você encontrou na mão. O que ele achou que você não viu? Por quê?

</details>

## ✅ Critérios de aprovação

- [ ] 3 flags corretas
- [ ] `ataque.md` com comandos reais (não "usei o comando X")
- [ ] `deteccao.md` cobrindo recon, credencial, lateral e escalada
- [ ] `hardening.md` com 5 correções plausíveis
- [ ] Tempo registrado

## 🧠 Depois do desafio

1. Repita o lab em **menos tempo**. A segunda execução é onde o aprendizado fixa.
2. Refilma fazendo o caminho inverso: abra os logs e explique o ataque **sem** olhar suas anotações.
3. Se quiser dificultar: edite o `setup.sh` e remova uma das pistas. O lab é seu.

---

<details>
<summary>🔓 Gabarito comentado (spoiler)</summary>

Veja [`solution.md`](solution.md) — apenas para conferência **depois** do cronômetro.

</details>
