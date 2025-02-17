# HackConRD-AD
HackConRD - Atacando y Defendiendo Active Directory.


## Vulnerabilidades a Explotar Durante el Workshop

### Acceso Inicial
Técnicas utilizadas por hackers una vez que alcanzan la red corporativa.
- Kerberoasting
- ASREPRoasting
- SMB Relay

### Explotación
Técnicas de Movimiento Lateral, Escalada de Privilegios y/o Enumeración de AD
- Enumeración con Bloodhound
- ADCS ESC4
- Abusos de ACL
  - Generic Write
  - RBCD
  - Shadow Credentials

### Post-Explotación
Técnicas utilizadas por hackers para mantener persistencia en el dominio
- Pass-the-Hash
- Golden Ticket
- DCSync (NTDS.dit)