# 📋 Cola de comandos

Referência rápida para o lab. Não é para decorar — é para consultar.

## Reconhecimento do host

```bash
hostnamectl                     # SO, kernel, arquitetura
uname -a                        # kernel e build
cat /etc/os-release            # distro
uptime                          # tempo ligado e carga
whoami && id                    # usuário e grupos
sudo -l                         # o que posso rodar como root
env                             # variáveis de ambiente
ss -tulpn                       # portas escutando
ps aux --sort=-%mem | head      # processos que mais consomem
```

## Usuários e grupos

```bash
cat /etc/passwd                 # contas do sistema
awk -F: '$3>=1000 {print $1}' /etc/passwd   # contas humanas
cat /etc/group                  # grupos
last -a | head                  # últimos logins
who                             # sessões ativas
getent passwd dev01             # dados de um usuário
```

## Arquivos e permissões

```bash
ls -la                          # incluindo ocultos
find /caminho -type f -name "*.conf"
find / -perm -4000 -type f 2>/dev/null      # SUID
find / -perm -2000 -type f 2>/dev/null      # SGID
find / -perm -0002 -type f 2>/dev/null      # gravável por todos
find / -writable -type d 2>/dev/null        # diretórios graváveis
stat arquivo                    # permissões, dono, datas
getfacl arquivo                 # ACLs
chmod 640 arquivo               # dono rw, grupo r, outros nada
chown user:group arquivo
```

## Busca de conteúdo

```bash
grep -r "senha" /caminho 2>/dev/null
grep -rn "FLAG{" / 2>/dev/null
grep -i "password\|passwd\|secret\|token" -r . 2>/dev/null
```

## Credenciais (dentro do lab)

```bash
cat ~/.bash_history
ls -la ~/.ssh/ && cat ~/.ssh/id_rsa
find / -name "*.env" -o -name "*.bak" -o -name "*.old" 2>/dev/null
echo "UzNuaDQtREItMjAyNA==" | base64 -d ; echo
```

## Escalada (contexto do lab)

```bash
sudo -l
find / -perm -4000 -type f 2>/dev/null
cat /etc/cron.d/* 2>/dev/null
ls -la /etc/cron.d/ /etc/cron.*/ 2>/dev/null
getcap -r / 2>/dev/null
cat /etc/sudoers.d/* 2>/dev/null
```

GTFOBins (referência de binários abusáveis): <https://gtfobins.github.io/>

## Logs (Blue Team)

```bash
sudo tail -f /var/log/auth.log
sudo journalctl -u ssh --since "1 hour ago"
sudo journalctl -xe
lastlog
lastb
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn
grep "Accepted" /var/log/auth.log
```

## auditd

```bash
sudo systemctl status auditd
sudo auditctl -l                       # regras carregadas
sudo ausearch -k cyberlab_sudo         # busca por chave
sudo aureport --auth                   # relatório de autenticação
sudo aureport -f --summary             # acesso a arquivos
sudo ausearch -ts today -m EXECVE      # comandos executados hoje
sudo augenrules --load                 # recarrega regras
```

## systemd

```bash
systemctl list-units --type=service --state=running
systemctl status nome
systemctl cat nome
systemctl list-timers
systemctl daemon-reload
```

## Git (para publicar o lab)

```bash
git init
git add .
git commit -m "feat: laboratorio de red e blue team em linux"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/linux-cyber-lab.git
git push -u origin main
```
