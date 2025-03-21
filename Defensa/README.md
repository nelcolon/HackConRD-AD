# 🔒 Defensa

Este directorio contiene la información de ataque para el workshop de **"Ataque y Defensa de Active Directory"**.

## Conexion Remota a los Domain Controllers

#### DC01
```bash
xfreerdp3 /v:192.168.56.10 /u:Administrator /p:8dCT-DJjgScp
```

#### DC02
```bash
xfreerdp3 /v:192.168.56.11 /u:Administrator /p:NgtI75cKV+Pu
```

## 📢 Para el archivo: **GOAD_HackConRD2025_GPO**

Este archivo describe la estructura que recomendamos crear mediante una política de Active Directory (GPO). Contiene las mitigaciones básicas diseñadas para el ambiente específico de **Active Directory GOAD** (Game Of Active Directory). 

**Importante:** Esta estructura está pensada para el ambiente **GOAD** y **no debe ser ejecutada en otros entornos** sin antes verificar que las configuraciones sean adecuadas.

## 📢 Para el archivo: **GOAD_HackConRD2025_Script_AD**


- **Guardar como `.ps1`**: Este script debe guardarse con la extensión `.ps1` (por ejemplo, `GOAD_HackConRD2025_Script_AD.ps1`).
  
El script debe ser ejecutado con privilegios de administrador en el controlador de dominio donde se aplicará la configuración.
Este script está diseñado específicamente para el entorno de **Active Directory GOAD**. **No debe ser ejecutado en otros entornos** sin primero verificar que las configuraciones sean apropiadas.

---
👾 ¡Gracias por leer!👾
❤️ **Con amor, GitHub: [J0s3F3lix](https://github.com/J0s3F3lix)**  
