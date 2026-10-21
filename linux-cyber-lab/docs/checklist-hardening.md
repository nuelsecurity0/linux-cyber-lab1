# 🛡️ Checklist de hardening

Use no lab 08. Cada item tem o comando de verificação e o resultado esperado.
O script `setup/verify.sh` testa automaticamente os itens marcados com 🤖.

| # | Item | Como verificar | Esperado |
| :-: | :-- | :-- | :-- |
| 1 | 🤖 SUID indevido removido | `find /opt/cyberlab -perm -4000 -type f 2>/dev/null` | Nenhum resultado |
| 2 | 🤖 Regra de sudo insegura removida | `sudo ls /etc/sudoers.d/` | Sem `cyberlab-labs` (ou sem `NOPASSWD`) |
| 3 | 🤖 Sem arquivos world-writable no lab | `find /opt/cyberlab /srv/cyberlab -perm -0002 -type f 2>/dev/null` | Nenhum resultado |
| 4 | 🤖 Script de cron sem escrita global | `stat -c '%a %U' /opt/cyberlab/scripts/maintenance.sh` | `700 root` (ou arquivo removido) |
| 5 | 🤖 Chave SSH protegida | `stat -c '%a' /home/dev01/.ssh/id_rsa` | `600` (ou chave removida) |
| 6 | 🤖 Contas do lab bloqueadas/removidas | `passwd -S dev01; passwd -S dev02` | `L` (locked) ou usuário inexistente |
| 7 | 🤖 Auditoria ativa | `sudo auditctl -l \| grep cyberlab` | Pelo menos 1 regra |
| 8 | 🤖 Arquivo sensível restrito | `stat -c '%a' /root/flag3.txt` | `600` (ou removido) |

## Itens extras (manuais, sem verificação automática)

| # | Item | Como verificar | Esperado |
| :-: | :-- | :-- | :-- |
| 9 | Histórico com credenciais limpo | `grep -i "pass\|senha" /home/dev01/.bash_history` | Nada sensível |
| 10 | Serviços desnecessários desligados | `ss -tulpn` | Só o que precisa |
| 11 | SSH sem login de root | `grep -i permitrootlogin /etc/ssh/sshd_config` | `no` / `prohibit-password` |
| 12 | Senhas fortes nos usuários do lab | `sudo chage -l dev01` | Política definida |
| 13 | Backup com permissão correta | `stat -c '%a' /srv/cyberlab/backup` | `700` |

## Como pontuar no lab 08

```bash
sudo ./setup/verify.sh
```

O script mostra **PASS/FAIL** em cada item e uma pontuação final. Meta: **8/8**.

> Corrigir sem entender é só "clicar em next". Para cada item que passar, escreva em uma linha **qual era o risco** e **por que a correção resolve**.
