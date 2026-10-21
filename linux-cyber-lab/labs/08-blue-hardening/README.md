# Lab 08 — Hardening validado

> 🔵 **Blue Team** · ⭐⭐ Intermediário · ⏱️ ~30 min · 🏅 250 pontos
>
> Pré-requisito: o lab montado (`sudo ./setup/setup.sh`). **Não rode o teardown** — ele apaga o cenário e você perde o exercício.

## 🎯 Objetivo

Fechar o ciclo: pegar o host que **você invadiu** nos labs 01–05 e deixá-lo resistente aos mesmos ataques. No final, um script verifica seu trabalho — sem subjetividade.

Meta: **8/8 no `verify.sh`**.

Isso não é "clicar em corrigir". Para cada item você precisa entender **qual ataque ele bloqueia**.

## 🧩 Cenário

Você assumiu a administração do servidor depois do incidente. O gestor pediu:

> "Quero o mesmo servidor, mas se alguém repetir o ataque de ontem, não pode funcionar."

Orçamento: 30 minutos. Sem reinstalar o SO.

## 📌 Tarefas

### Passo 0 — Antes de mudar, registre o estado

```bash
cd ~/linux-cyber-lab

# tire uma "foto" do estado atual
{
  find / -perm -4000 -type f 2>/dev/null
  find /opt/cyberlab /srv/cyberlab -perm -0002 -type f 2>/dev/null
  sudo cat /etc/sudoers.d/cyberlab-labs 2>/dev/null
  ls -l /home/dev01/.ssh/ 2>/dev/null
} > antes.txt
```

Isso é o seu **baseline**. Sem ele, você não prova que mudou nada.

---

### Passo 1 — Remover o SUID indevido

```bash
find /opt/cyberlab -perm -4000 -type f 2>/dev/null
sudo chmod u-s /opt/cyberlab/bin/.cache-helper

# OU remover o binário
sudo rm -f /opt/cyberlab/bin/.cache-helper
```

**Pergunta:** por que remover o bit SUID é melhor que só apagar o arquivo? (Dica: pense em auditoria.)

---

### Passo 2 — Remover a regra de sudo insegura

```bash
sudo cat /etc/sudoers.d/cyberlab-labs
sudo rm /etc/sudoers.d/cyberlab-labs
```

**Pergunta:** se o time realmente precisar que o `dev01` use `less` como root, como fazer com segurança? (Pense: `sudoedit`, grupos, `systemd-run`, ou simplesmente não fazer.)

> ⚠️ Nunca edite `/etc/sudoers` direto. Use `visudo` (ou `visudo -f`). Um erro de sintaxe pode te trancar fora do root.

---

### Passo 3 — Corrigir permissões do script de cron

```bash
sudo chown root:root /opt/cyberlab/scripts/maintenance.sh
sudo chmod 700 /opt/cyberlab/scripts/maintenance.sh
sudo ls -l /opt/cyberlab/scripts/maintenance.sh
```

Agora só root lê, escreve e executa. O cron continua funcionando (ele roda como root), mas ninguém mais consegue alterar o conteúdo.

**Pergunta:** por que `700` e não `755`? O que `755` ainda permitiria?

---

### Passo 4 — Proteger a chave SSH

```bash
sudo chmod 700 /home/dev01/.ssh
sudo chown -R dev01:dev01 /home/dev01/.ssh
sudo chmod 600 /home/dev01/.ssh/id_rsa
sudo ls -la /home/dev01/.ssh/
```

**Pergunta:** com a chave em `600`, um atacante que já tem shell como `dev01` ainda consegue usá-la? O que **de fato** resolveria isso?

---

### Passo 5 — Bloquear as contas do lab

```bash
# execute como kali (com sudo) ou como root
sudo passwd -l dev01
sudo passwd -l dev02
sudo passwd -S dev01      # esperado: dev01 L ...
sudo usermod -s /usr/sbin/nologin svc-backup
```

`passwd -l` prefixa a senha com `!` em `/etc/shadow`, invalidando o login por senha sem apagar a conta.

**Pergunta:** o que acontece com a sessão que já estava aberta? Bloquear a conta encerra o acesso existente?

---

### Passo 6 — Garantir auditoria ativa

```bash
sudo systemctl enable --now auditd
sudo auditctl -l | grep cyberlab
sudo augenrules --load
```

**Pergunta:** de que adianta auditar se você não olha o log? Cite um alerta que você criaria a partir dessas regras.

---

### Passo 7 — Restringir o arquivo sensível

```bash
sudo chmod 600 /root/flag3.txt
sudo ls -l /root/flag3.txt
```

Sim, ele já estava `600`. O exercício é **verificar**, não assumir.

---

### Passo 8 — Rodar o verificador

```bash
sudo ./setup/verify.sh
```

Saída esperada no final:

```
  RESULTADO: 8/8 - HARDENING COMPLETO
```

Se algum item falhar, o script diz exatamente o que fazer. Corrija e rode de novo.

---

### Passo 9 — Provar que o ataque não funciona mais

Tente repetir o ataque do lab 03:

```bash
su - dev01              # deve falhar (conta bloqueada)
sudo -l                 # sem a regra, sem NOPASSWD
ls -l /opt/cyberlab/bin/.cache-helper   # sem SUID (ou ausente)
ls -l /opt/cyberlab/scripts/maintenance.sh   # 700 root
```

**Entrega:** cole as saídas que mostram o ataque bloqueado.

## 📌 Entregáveis

1. `antes.txt` e `depois.txt` (mesmos comandos do passo 0, após o hardening)
2. `hardening.md` com a tabela abaixo preenchida
3. Print ou texto do `verify.sh` com **8/8**

### Tabela de `hardening.md`

| # | Vulnerabilidade | Ataque que ela permitia | Correção aplicada | Como impediria |
| :-: | :-- | :-- | :-- | :-- |
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |
| 8 | | | | |

## 💡 Dicas

<details>
<summary>Dica 1 — verify.sh reprova mesmo eu tendo corrigido</summary>

Rode como root (`sudo`). Sem root, `auditctl` falha e o script pode não enxergar `/root`.

```bash
sudo ./setup/verify.sh
```

Se o problema for o item 7, confira:

```bash
sudo auditctl -l | grep cyberlab
```

Sem saída → as regras não estão carregadas. Carregue:

```bash
sudo augenrules --load
```

</details>

<details>
<summary>Dica 2 — "conta bloqueada" não é o mesmo que "senha vazia"</summary>

`passwd -l` coloca `!` antes do hash. `passwd -d` **apaga** a senha (deixa vazio) — isso é pior, permite login sem senha em algumas configurações. Não confunda.

Verificação correta:

```bash
sudo passwd -S dev01
# dev01 L 02/14/2026 0 99999 7 -1
#       ^ L = locked
```

</details>

<details>
<summary>Dica 3 — por que não apagar /opt/cyberlab inteiro</summary>

Tecnicamente passaria em vários itens. Mas:

- o `verify.sh` verifica **correção**, não destruição
- apagar o cenário não te ensina a diagnosticar o problema
- em produção, você não pode "rm -rf" no servidor para resolver um SUID indevido

O objetivo é aprender a cirurgia, não a amputação.

</details>

<details>
<summary>Dica 4 — além do laboratório (nível 2)</summary>

O host do lab é simplificado. Em um servidor real, você também faria:

```bash
# SSH: apenas chave, sem root direto
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sshd -t && sudo systemctl reload ssh

# /tmp sem execução de binários
# /etc/fstab: tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0

# atualizações automáticas de segurança
sudo apt install -y unattended-upgrades

# limite de tentativas de login
sudo apt install -y fail2ban
```

Não são exigidos pelo `verify.sh`, mas são o próximo nível.

</details>

<details>
<summary>Dica 5 — checklist completo</summary>

Veja [`docs/checklist-hardening.md`](../../docs/checklist-hardening.md). Ele lista os 8 itens automáticos + 5 manuais.

</details>

## ✅ Critérios de conclusão

- [ ] `verify.sh` com **8/8**
- [ ] `antes.txt` e `depois.txt` gerados
- [ ] Tabela com 8 linhas preenchida (causa → correção → efeito)
- [ ] Ataque do lab 03 falhando na prática
- [ ] Entendimento: você sabe explicar cada item em 1 frase

## 🧠 Para fechar o ciclo

1. O que você aprendeu como atacante que mudou sua forma de defender?
2. Qual correção tem melhor relação **impacto / esforço**?
3. Se tivesse 1 hora e não 30 minutos, o que faria depois?

---

<details>
<summary>🔓 Solução comentada (spoiler)</summary>

Veja [`solution.md`](solution.md).

</details>
