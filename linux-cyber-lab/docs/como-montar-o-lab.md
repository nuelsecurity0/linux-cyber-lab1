# 🖥️ Como montar o laboratório

Passo a passo para preparar a VM Kali Linux onde o lab vai rodar.

## 1. Requisitos

| Item | Mínimo | Recomendado |
| :-- | :-- | :-- |
| RAM | 2 GB | 4 GB |
| vCPU | 2 | 2 |
| Disco | 15 GB | 25 GB |
| Hypervisor | VirtualBox / VMware / UTM | VirtualBox |

Com 2 GB o Kali funciona, mas navegador + terminal + `auditd` ficam apertados.

## 2. Baixar o Kali

- Site oficial: <https://www.kali.org/get-kali/>
- Escolha **Installer Images → Virtual Machines** (`.ova` / `.vmx`), que já vem pronta.
- Verifique o **SHA256** do arquivo baixado antes de importar.

> ⚠️ Baixe somente de `kali.org`. Imagens de terceiros podem vir comprometidas — e isso não é o tipo de "lab" que você quer.

## 3. Importar a VM

**VirtualBox**

1. `Arquivo → Importar Appliance` → selecione o `.ova`
2. Ajuste: 4 GB RAM, 2 CPUs, rede em **NAT** (padrão)
3. Inicie e faça login com `kali/kali`

**VMware Workstation/Player**

1. `File → Open` → selecione o `.vmx`
2. `Edit → Virtual Machine Settings` → 4 GB RAM, 2 CPUs

## 4. Primeiros ajustes

```bash
# Atualize o sistema (pode demorar)
sudo apt update && sudo apt full-upgrade -y

# Ferramentas que o lab usa
sudo apt install -y git curl auditd

# Confirme que está tudo ok
uname -a
id
sudo -v
```

## 5. Snapshot (não pule esta etapa)

Com a VM limpa e atualizada:

1. Desligue a VM (ou pause)
2. `Snapshots → Take Snapshot`
3. Nome: **`limpo-antes-do-lab`**

Se algo der errado, você volta em 30 segundos em vez de reinstalar tudo.

Snapshots sugeridos ao longo do lab:

| Snapshot | Quando criar |
| :-- | :-- |
| `limpo-antes-do-lab` | após instalar Kali + updates |
| `lab-montado` | depois de rodar `setup.sh` |
| `pos-privesc` | depois do lab 03 (root obtido) |

## 6. Rodar o setup

```bash
git clone https://github.com/SEU-USUARIO/linux-cyber-lab.git
cd linux-cyber-lab
sudo ./setup/setup.sh
```

O script cria:

- Usuários de laboratório (`dev01`, `dev02`, `svc-backup`)
- Diretório `/opt/cyberlab` com dados, logs e scripts
- Configurações **intencionalmente vulneráveis** (SUID, sudoers, cron gravável)
- Flags escondidas
- Regras de auditoria

Ao final ele imprime um resumo. **Não leia o resumo inteiro se quiser o fator surpresa** — ele lista o que foi criado.

## 7. Rede do lab

O laboratório é **local**. Você não precisa de internet durante os exercícios (só para o `git clone` e `apt`).

Se quiser praticar rede depois:

- **NAT**: VM tem internet, mas não é acessível de fora (mais seguro)
- **Host-only**: só sua máquina conversa com a VM
- **Bridge**: a VM entra na sua rede — ⚠️ **evite** fazer scan na rede doméstica

## 8. Problemas comuns

| Sintoma | Causa provável | Solução |
| :-- | :-- | :-- |
| `Permission denied` ao rodar `setup.sh` | script sem permissão | `chmod +x setup/setup.sh` |
| `bad interpreter: /bin/bash^M` | arquivo salvo com CRLF (Windows) | `sed -i 's/\r$//' setup/*.sh` ou `dos2unix` |
| `useradd: user already exists` | setup rodado duas vezes | `sudo ./setup/reset.sh` |
| `auditctl: command not found` | `auditd` não instalado | `sudo apt install auditd` |
| Lab "não tem nada" | setup não rodou como root | `sudo ./setup/setup.sh` |
| VM muito lenta | pouca RAM | aumente para 4 GB e desligue o navegador |

## 9. Depois do lab

```bash
# Remover tudo que o lab criou
sudo ./setup/teardown.sh

# Ou restaurar o snapshot "limpo-antes-do-lab"
```

Se você for publicar suas anotações no GitHub, **não suba** `flags.txt`, `respostas.md` nem relatórios com dados reais da sua rede.
