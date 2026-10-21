<div align="center">

# 🐧 Linux Cyber Lab

**Laboratório de Red Team + Blue Team para praticar em uma VM Kali Linux**

![Nível](https://img.shields.io/badge/n%C3%ADvel-iniciante%20%E2%86%92%20intermedi%C3%A1rio-blue)
![Ambiente](https://img.shields.io/badge/ambiente-Kali%20Linux-557C94?logo=kalilinux&logoColor=white)
![Labs](https://img.shields.io/badge/labs-8-orange)
![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-green)

</div>

> [!WARNING]
> **Este laboratório cria vulnerabilidades de propósito.**
> Rode **apenas** dentro da VM do lab, nunca em máquina de produção, trabalho ou de terceiros.
> Tudo o que você aprender aqui deve ser usado em ambientes autorizados.

---

## 🎯 Objetivo

Você vai atuar dos **dois lados** do mesmo servidor:

| Trilha | Papel | O que você treina |
| :-- | :-- | :-- |
| 🔴 **Red** | Atacante | Reconhecimento local, caça a credenciais, escalada de privilégio, persistência |
| 🔵 **Blue** | Analista | Leitura de logs, timeline de incidente, auditoria com `auditd`, hardening |

O diferencial: **as mesmas máquinas e artefatos** servem para o ataque e para a detecção. Você aprende a invadir e, em seguida, a encontrar o que você mesmo fez.

Ao final você terá produzido:

- ✅ 3 flags capturadas (Red Team)
- ✅ 1 relatório de incidente com timeline e IOCs (Blue Team)
- ✅ 1 checklist de hardening validado por script
- ✅ 1 documento de persistência com as detecções correspondentes

---

## 📚 Trilha de labs

| # | Lab | Trilha | Dificuldade | Tempo | Pontos |
| :-: | :-- | :-: | :-: | :-: | :-: |
| 01 | [Reconhecimento local](labs/01-reconhecimento/README.md) | 🔴 Red | ⭐ | 20 min | 100 |
| 02 | [Caça a credenciais](labs/02-credenciais/README.md) | 🔴 Red | ⭐⭐ | 30 min | 150 |
| 03 | [Permissões e escalada](labs/03-privesc/README.md) | 🔴 Red | ⭐⭐ | 40 min | 200 |
| 04 | [Persistência + detecção](labs/04-persistencia/README.md) | 🔴🔵 | ⭐⭐⭐ | 40 min | 200 |
| 05 | [Desafio final cronometrado](labs/05-desafio-final/README.md) | 🔴 | ⭐⭐⭐ | 45 min | 300 |
| 06 | [Logs e relatório de incidente](labs/06-blue-logs/README.md) | 🔵 Blue | ⭐⭐ | 40 min | 200 |
| 07 | [Auditoria com auditd](labs/07-blue-auditd/README.md) | 🔵 Blue | ⭐⭐⭐ | 30 min | 150 |
| 08 | [Hardening validado](labs/08-blue-hardening/README.md) | 🔵 Blue | ⭐⭐ | 30 min | 250 |

**Total: 1.550 pontos** (placar em [`flags.md`](flags.md))

> 💡 Sugestão de ordem: **01 → 02 → 03 → 06 → 04 → 07 → 05 → 08**.
> Assim você ataca, entende a detecção e só depois escala de verdade.

---

## 🧰 Pré-requisitos

- VM **Kali Linux** (VirtualBox, VMware ou UTM) — veja [como montar o lab](docs/como-montar-o-lab.md)
- 4 GB de RAM e 20 GB de disco (recomendado)
- Acesso `sudo` dentro da VM
- Vontade de quebrar coisas e consertar depois 🙂

Não é necessário ter experiência prévia com pentest. Saber navegar no terminal ajuda.

---