# Atacando

Este directorio contiene la información de ataque para el workshop de "Ataque y Defensa de Active Directory".

### Enumeración Inicial

Identificando los controladores de dominio:
```shell
nslookup -type=srv _ldap._tcp.dc._msdcs.sevenkingdoms.local 192.168.56.10
_ldap._tcp.dc._msdcs.sevenkingdoms.local        service = 0 100 389 kingslanding.sevenkingdoms.local

nslookup -type=srv _ldap._tcp.dc._msdcs.north.sevenkingdoms.local 192.168.56.10
_ldap._tcp.dc._msdcs.north.sevenkingdoms.local  service = 0 100 389 winterfell.north.sevenkingdoms.local

nslookup -type=srv _ldap._tcp.dc._msdcs.essos.local 192.168.56.10
_ldap._tcp.dc._msdcs.essos.local        service = 0 100 389 meereen.essos.local

```

Por temas de kerberos, ponemos esta información en el `/etc/hosts`
```
# GOAD
192.168.56.10   sevenkingdoms.local kingslanding.sevenkingdoms.local kingslanding
192.168.56.11   winterfell.north.sevenkingdoms.local north.sevenkingdoms.local winterfell
192.168.56.12   essos.local meereen.essos.local meereen
192.168.56.22   castelblack.north.sevenkingdoms.local castelblack
192.168.56.23   braavos.essos.local braavos
```

Para que Linux soporte kerberos instalamos el paquete `krb5-user` y luego deditamos `/etc/krb5.conf`

```conf
[libdefaults]
  default_realm = sevenkingdoms.local
  kdc_timesync = 1
  ccache_type = 4
  forwardable = true
  proxiable = true
  fcc-mit-ticketflags = true
[realms]
  north.sevenkingdoms.local = {
      kdc = winterfell.north.sevenkingdoms.local
      admin_server = winterfell.north.sevenkingdoms.local
  }
  sevenkingdoms.local = {
      kdc = kingslanding.sevenkingdoms.local
      admin_server = kingslanding.sevenkingdoms.local
  }
  essos.local = {
      kdc = meereen.essos.local
      admin_server = meereen.essos.local
  }
```


### Acceso Inicial

- Kerberoasting

> En caso de tener el problema `KRB_AP_ERR_SKEW(Clock skew too great)`, esto se resuelve con `rdate -n 192.168.56.11`

- SMB Relay


Se modifica la configuración de responder para apagar la opción **SMB** y **HTTP**, las localidades comunes son:
- `/etc/responder/Responder.conf`
- `/usr/share/responder/Responder.conf`