# Atacando

Este directorio contiene la información de ataque para el workshop de "Ataque y Defensa de Active Directory".

### Acceso Inicial
Técnicas utilizadas por hackers una vez que alcanzan la red corporativa.
- Kerberoasting
  - Vulnerable User is `north\jon.snow`
- ASREPRoasting
  - Vulnerable user is `north\brandon.stark`
- SMB Relay
  - Vulnerable users are `robb.stark` and `eddard.stark`

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