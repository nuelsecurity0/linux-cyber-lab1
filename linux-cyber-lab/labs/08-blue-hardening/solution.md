# 🔓 Solução — Lab 08

> ⚠️ **Spoiler.** Tente antes de abrir.

## Sequência completa (copiar e colar)

```bash
# 0. baseline
find / -perm -4000 -type f 2>/dev/null > /tmp/antes-suid.txt
find /opt/cyberlab /srv/cyberlab -perm -0002 -type f 2>/dev/null > /tmp/antes-ww.txt

# 1. SUID
sudo chmod u-s /opt/cyberlab/bin/.cache-helper

# 2. sudoers
sudo rm -f /etc/sudoers.d/cyberlab-labs

# 3. cron
sudo chown root:root /opt/cyberlab/scripts/maintenance.sh
sudo chmod 700 /opt/cyberlab/scripts/maintenance.sh

# 4. chave SSH
sudo chmod 700 /home/dev01/.ssh
sudo chown -R dev01:dev01 /home/dev01/.ssh
sudo chmod 600 /home/dev01/.ssh/id_rsa

# 5. contas
sudo passwd -l dev01
sudo passwd -l dev02
sudo usermod -s /usr/sbin/nologin svc-backup

# 6. auditoria
sudo systemctl enable --now auditd
sudo augenrules --load

# 7. arquivo sensível
sudo chmod 600 /root/flag3.txt

# 8. verificação
sudo ./setup/verify.sh
```

Saída esperada:

```
  [PASS] Nenhum binario SUID em /opt/cyberlab
  [PASS] Regra de sudo NOPASSWD removida
  [PASS] Sem arquivos world-writable no lab
  [PASS] Script de manutencao restrito
  [PASS] Chave SSH protegida ou removida
  [PASS] Contas do lab bloqueadas ou removidas
  [PASS] Regras de auditoria carregadas
  [PASS] Arquivo sensivel com permissao 600

  RESULTADO: 8/8 - HARDENING COMPLETO
```

## Por que cada correção funciona

| # | Correção | Ataque bloqueado | Mecanismo |
| :-: | :-- | :-- | :-- |
| 1 | `chmod u-s` | `.cache-helper` como root | sem o bit, o binário roda com o UID do chamador |
| 2 | `rm /etc/sudoers.d/cyberlab-labs` | `sudo less` → `!sh` | o usuário deixa de ter qualquer comando como root |
| 3 | `chmod 700` no script | editar cron de root | só root escreve; o cron continua executando |
| 4 | `chmod 600` na chave | copiar chave e usá-la | outros usuários não leem o arquivo |
| 5 | `passwd -l` | login com senha vazada | hash inválido (`!`) → autenticação sempre falha |
| 6 | regras carregadas | alterações silenciosas | kernel registra escrita em arquivos sensíveis |
| 7 | `chmod 600` | leitura da flag por outro usuário | permissão de leitura restrita ao dono |
| 8 | verificação | confiança cega | mede o estado real, não a intenção |

## Detalhes importantes

### 1. `chmod u-s` vs apagar

- **Apagar** resolve o risco, mas some com a evidência de que o problema existiu.
- **Remover o bit** mantém o arquivo para análise e ensina o conceito. Em produção, dependendo do caso, o correto é remover o binário e registrar o incidente.

### 2. `700` vs `755` no script

`755` permite **leitura** por qualquer usuário. Um atacante não poderia alterar, mas poderia:

- descobrir caminhos internos, tokens, lógica de backup
- usar o conteúdo para planejar outro ataque

`700` fecha leitura e escrita. O cron roda como root, então não perde funcionalidade.

### 3. Chave em `600`

Ainda é **utilizável** por quem já é `dev01` ou root. `600` impede que **outros usuários** leiam a chave. Para reduzir o impacto real:

- passphrase na chave
- rotação periódica
- chaves por host, não compartilhadas
- `authorized_keys` com `command=` restrito quando possível

### 4. `passwd -l` e sessões abertas

Bloquear a conta **não derruba** sessões já autenticadas. Para encerrar:

```bash
sudo pkill -KILL -u dev01
sudo loginctl terminate-user dev01
```

Em um incidente real, bloqueio + encerramento de sessão + rotação de credenciais andam juntos.

### 5. Auditoria sem monitoramento

As regras só gravam. O valor aparece quando alguém consulta:

```bash
sudo ausearch -k cyberlab_sudo -ts today
sudo aureport --auth --summary
```

Um alerta simples: "evento com `key=cyberlab_identidade` fora do horário de deploy" → e-mail/SIEM.

## Diferenças entre o lab e produção

| Lab | Produção |
| :-- | :-- |
| 3 usuários | centenas, com ciclo de vida |
| Flag em `/root` | dados de clientes, chaves, backups |
| `verify.sh` | CIS Benchmark, OpenSCAP, Ansible |
| Log local | SIEM + retenção legal |
| Sem firewall | segmentação, WAF, IDS/IPS |

O raciocínio é o mesmo; a escala muda.

## Checklist final de maturidade

- [ ] Inventário de contas (quem precisa de shell?)
- [ ] Princípio do menor privilégio em `sudo`
- [ ] Baseline de SUID/SGID com alerta em diff
- [ ] Chaves SSH com passphrase e rotação
- [ ] Auditoria com retenção remota
- [ ] Patch management
- [ ] Revisão trimestral de permissões
- [ ] Simulação de ataque (purple team) periódica

## Lições

1. **Hardening é remover capacidade, não adicionar ferramenta.**
2. A correção mais barata costuma ser a mais eficaz: `chmod`, `rm`, `passwd -l`.
3. Sem baseline e verificação, "está seguro" é opinião.
4. Todo controle tem custo e falso positivo. Escolha os que você consegue operar.
