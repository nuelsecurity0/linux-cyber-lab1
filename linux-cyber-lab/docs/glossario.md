# 📖 Glossário

Termos que aparecem no lab, em linguagem simples.

| Termo | Significado |
| :-- | :-- |
| **Red Team** | Time que simula um atacante real para testar as defesas. |
| **Blue Team** | Time que defende: monitora, detecta e responde a incidentes. |
| **Purple Team** | Trabalho conjunto: o ataque vira detecção. É o espírito deste lab. |
| **Recon** | Reconhecimento. Coletar informação antes de agir. |
| **Enumeração** | Listar usuários, serviços, permissões e arquivos de um alvo. |
| **SUID** | Bit de permissão que faz um programa rodar com o privilégio do dono (se o dono é root, roda como root). |
| **SGID** | Similar ao SUID, mas aplica o grupo do arquivo/diretório. |
| **Sticky bit** | Em diretórios como `/tmp`: só o dono apaga o próprio arquivo. |
| **Privesc** | *Privilege escalation*: sair de usuário comum para root. |
| **Lateral movement** | Pular de uma conta/máquina comprometida para outra. |
| **Persistência** | Mecanismo que mantém o acesso após reboot/logout (cron, systemd, chave SSH). |
| **IOC** | *Indicator of Compromise*: IP, hash, usuário, arquivo que indica invasão. |
| **TTP** | Táticas, técnicas e procedimentos do atacante (o "jeito" de agir). |
| **MITRE ATT&CK** | Catálogo público de técnicas de ataque, usado para classificar detecções. |
| **Dwell time** | Tempo que o atacante fica dentro do ambiente sem ser detectado. |
| **Hardening** | Reduzir superfície de ataque: fechar portas, corrigir permissões, remover serviços. |
| **auditd** | Serviço de auditoria do Linux: registra chamadas de sistema e alterações em arquivos. |
| **GTFOBins** | Site que cataloga binários legítimos que podem ser abusados para escalar privilégio. |
| **World-writable** | Arquivo/diretório que qualquer usuário pode escrever (`chmod o+w`). |
| **Flag** | String escondida que prova que você concluiu a etapa (`FLAG{...}`). |
| **Snapshot** | "Foto" do estado da VM, usada para voltar atrás. |
