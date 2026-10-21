# 🔓 Solução — Lab 07

> ⚠️ **Spoiler.** Tente antes de abrir.

## 1. Estado do serviço

```bash
sudo systemctl status auditd --no-pager
sudo auditctl -s
```

```
enabled 1
failure 1
pid 812
rate_limit 0
```

- `enabled 1` → auditoria ligada no kernel
- `failure 1` → falhas são registradas
- `rate_limit 0` → sem limite (em produção, limite evita flood)

## 2. Regras carregadas

```bash
sudo auditctl -l | grep cyberlab
```

7 regras, como no enunciado. `-p wa` = **w**rite (escrita) + **a**ttribute change (`chmod`, `chown`, `setxattr`).

## 3. Eventos e evidências

### a) Novo usuário

```bash
sudo useradd lab07test
sudo ausearch -k cyberlab_identidade -i -ts recent
```

Trecho esperado:

```
type=SYSCALL msg=audit(...): arch=c000003e syscall=257 success=yes exit=3
  ... auid=1000 uid=0 ... comm="useradd" exe="/usr/sbin/useradd" key="cyberlab_identidade"
type=PATH msg=audit(...): item=0 name="/etc/passwd" ...
```

Leitura: `useradd` abriu `/etc/passwd` para escrita, com `auid=1000` (sessão do `kali`) e `uid=0` (via `sudo`).

### b) Alteração em sudoers.d

```bash
echo "# lab07 - teste de auditoria" | sudo tee -a /etc/sudoers.d/cyberlab-labs
sudo ausearch -k cyberlab_sudo -i -ts recent
```

```
type=SYSCALL ... comm="tee" exe="/usr/bin/tee" key="cyberlab_sudo"
type=PATH ... name="/etc/sudoers.d/cyberlab-labs" ...
type=PROCTITLE ... proctitle=746565002D61002F6574632F7375646F6572732E64...
```

`proctitle` em hexadecimal decodifica para `tee -a /etc/sudoers.d/cyberlab-labs`, incluindo o texto inserido em alguns casos.

### c) Escrita no diretório do cron

```bash
sudo touch /opt/cyberlab/scripts/lab07-teste.txt
sudo ausearch -k cyberlab_scripts -i -ts recent
```

```
type=SYSCALL ... comm="touch" exe="/usr/bin/touch" key="cyberlab_scripts"
type=PATH ... name="/opt/cyberlab/scripts/lab07-teste.txt"
```

## 4. Regras novas

`/etc/audit/rules.d/cyberlab-lab07.rules`:

```
## Lab 07 - regras do aluno
-a always,exit -F arch=b64 -S execve -F exe=/usr/sbin/useradd -k cyberlab_useradd
-w /tmp -p x -k cyberlab_tmp_exec
```

```bash
sudo augenrules --load
sudo auditctl -l | grep -E "cyberlab_useradd|cyberlab_tmp_exec"
```

Teste:

```bash
sudo useradd lab07test2
cp /bin/true /tmp/lab07-exec && /tmp/lab07-exec

sudo ausearch -k cyberlab_useradd -i -ts recent
sudo ausearch -k cyberlab_tmp_exec -i -ts recent
```

Esperado em `cyberlab_useradd`:

```
type=SYSCALL ... syscall=59 success=yes ... comm="useradd" exe="/usr/sbin/useradd"
  key="cyberlab_useradd"
```

Esperado em `cyberlab_tmp_exec`:

```
type=SYSCALL ... syscall=59 ... comm="lab07-exec" exe="/tmp/lab07-exec"
  key="cyberlab_tmp_exec"
```

> Observação: `-w /tmp -p x` **não** captura todos os `execve`, só o acesso com permissão de execução no caminho monitorado. Para cobertura total de execução, usa-se uma regra `execve` global (bem mais cara).

## 5. Relatórios

```bash
sudo aureport --auth --summary
```

```
total  auth  failures
=====  ====  ========
   12     9         9
```

```bash
sudo aureport -f --summary | head
sudo aureport --failed --summary
```

Em um relatório de incidente, `aureport --auth` responde "quantas falhas de autenticação?" e `aureport -f` responde "quais arquivos foram tocados?".

## 6. `deteccoes.md`

| Cenário | Regra | Chave | Busca | Falso positivo |
| :-- | :-- | :-- | :-- | :-- |
| novo usuário | `-w /etc/passwd -p wa` | `cyberlab_identidade` | `ausearch -k cyberlab_identidade` | `apt` criando usuário de pacote |
| mudança em sudo | `-w /etc/sudoers.d/ -p wa` | `cyberlab_sudo` | `ausearch -k cyberlab_sudo` | administrador editando regra |
| execução em `/tmp` | `-w /tmp -p x` | `cyberlab_tmp_exec` | `ausearch -k cyberlab_tmp_exec` | instaladores que rodam script em `/tmp` |
| chave SSH no root | `-w /root/.ssh/ -p wa` | `cyberlab_ssh` | `ausearch -k cyberlab_ssh` | automação de backup |
| script de cron alterado | `-w /opt/cyberlab/scripts/ -p wa` | `cyberlab_scripts` | `ausearch -k cyberlab_scripts` | deploy legítimo |

### Custo do auditd

- Cada regra casada gera **vários registros** (`SYSCALL`, `PATH`, `PROCTITLE`, `CWD`). Uma regra ampla como `-w /tmp -p wa` pode gerar **milhares de eventos por minuto** em um servidor com muitos processos.
- O impacto de performance é pequeno quando as regras são específicas; cresce com o volume.
- Logs crescem rápido: `audit.log` precisa de rotação e, idealmente, envio para servidor remoto.
- Em produção: regras por **caminho sensível**, `-F auid!=4294967295` (ignorar processos sem sessão de usuário, como daemons de boot) e revisão periódica do que está sendo auditado.

## 7. Limpeza

```bash
sudo userdel -r lab07test 2>/dev/null
sudo userdel -r lab07test2 2>/dev/null
sudo rm -f /opt/cyberlab/scripts/lab07-teste.txt /tmp/lab07-exec
sudo sed -i '/lab07 - teste/d' /etc/sudoers.d/cyberlab-labs
```

As regras que você criou podem ficar (são úteis no lab 08). Se quiser remover:

```bash
sudo rm /etc/audit/rules.d/cyberlab-lab07.rules
sudo augenrules --load
```

> ⚠️ O lab 08 verifica `auditctl -l | grep cyberlab`. Remover **todas** as regras (`/etc/audit/rules.d/cyberlab.rules`) reprova o item 7.

## Respostas às perguntas

1. **Por que auditd > bash_history?** O histórico é escrito pelo próprio usuário, pode ser editado, apagado (`history -c`) ou simplesmente não existir (shell não interativo). O `auditd` registra na camada de kernel, com `auid` e PID, mesmo para comandos executados por scripts.
2. **Se o atacante vira root**, ele pode parar o serviço, apagar `/var/log/audit/` e alterar regras. Mitigação: envio **imediato** para servidor remoto (`audisp-remote`, SIEM) e imutabilidade (`-e 2`, que trava as regras até reboot).
3. **Reduzir ruído de `/tmp`**: monitorar apenas `execve` com filtro de `auid`, excluir processos conhecidos, ou trocar por `mount` com `noexec` (aí a execução em `/tmp` deixa de ser possível — melhor que detectar).

## Lições

1. Auditoria responde "quem, o quê, quando, com qual processo" — mas só se a regra existir **antes**.
2. `auid` é o campo que separa "root agiu" de "usuário comum virou root".
3. Toda detecção tem custo. Regra boa é específica e explicável.
4. Detecção sem resposta a incidente é só barulho: o valor está no `aureport` + correlação com `auth.log`.
