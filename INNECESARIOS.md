# Archivos innecesarios / artefactos (Mercury)

Este documento lista los archivos que se consideran artefactos, históricos o temporales y que no son necesarios para compilar/ejecutar el proyecto con Lazarus. Se sugiere ignorarlos en VCS (`.gitignore`) o archivarlos si deseás conservar un snapshot.

## Resumen
- Conservá en el repo sólo el código fuente necesario: `*.pas`, `*.lpr`, `*.lpi`, `*.lps`, `*.lfm`, `*.inc`.
- Podés ignorar/archivar los siguientes archivos (generados por compilación o IDE):

## Archivos detectados (lista concreta)

### 1) Archivos compilados de Delphi (.dcu)
- UUtiles.dcu
- UServerSocket.dcu
- USensor.dcu
- Uprincipal.dcu
- UPresentacion.dcu
- UPreferencias.dcu
- UOpciones3D.dcu
- UGrafico.dcu
- UFormulas.dcu
- UEquipoInternet.dcu
- UEquipo.dcu
- UDiaJuliano.dcu
- UDataModule.dcu
- UConfiguracionInternet.dcu
- UConexionesRemotas.dcu
- UConexiones.dcu
- UConexionAuto.dcu
- UColor.dcu
- UCalculoParam.dcu
- UAnemometro.dcu
- PuertoSerie.dcu

### 2) Archivos compilados de Free Pascal / Lazarus (.ppu)
- USensor.ppu
- Uprincipal.ppu
- UPresentacion.ppu
- UPreferencias.ppu
- UFormulas.ppu
- UEquipo.ppu
- UDiaJuliano.ppu
- UUtiles.ppu
- UDataModule.ppu
- UConfiguracionInternet.ppu
- UConexionesRemotas.ppu
- UConexiones.ppu
- UConexionAuto.ppu
- UCalculoParam.ppu
- PuertoSerie.ppu
- (además hay muchos `.ppu` dentro de `lib\x86_64-win64\`)

### 3) Archivos del editor de diagramas / IDE (.ddp)
- UConexionAuto.ddp
- UColor.ddp
- UCalculoParam.ddp
- UAnemometro.ddp
- Uprincipal.ddp
- UPresentacion.ddp
- UPreferencias.ddp
- UOpciones3D.ddp
- UGrafico.ddp
- UDataModule.ddp
- UConfiguracionInternet.ddp
- UConexionesRemotas.ddp
- UConexiones.ddp

> Nota: los `.ddp` en este repo son archivos binarios de diagramas/diagram portfolio de Delphi. No afectan la compilación en Lazarus; son históricos.

### 4) Backups / autoguardados (`.~pas`, `.~dfm`, `*~`)
#### `*.~pas`
- UCalculoParam.~pas
- Uprincipal.~pas
- UPresentacion.~pas
- UPreferencias.~pas
- UOpciones3D.~pas
- USensor.~pas
- UGrafico.~pas
- UFormulas.~pas
- UEquipoInternet.~pas
- UEquipo.~pas
- UServerSocket.~pas
- UDataModule.~pas
- UConfiguracionInternet.~pas
- UConexionesRemotas.~pas
- UConexiones.~pas
- UUtiles.~pas
- UConexionAuto.~pas
- ServerSocket.~pas
- PuertoSerie.~pas

#### `*.~dfm`
- Uprincipal.~dfm
- UPresentacion.~dfm
- UPreferencias.~dfm
- UOpciones3D.~dfm
- UGrafico.~dfm
- UDataModule.~dfm
- UConfiguracionInternet.~dfm
- UConexionesRemotas.~dfm
- UConexionAuto.~dfm
- UCalculoParam.~dfm

### 5) Archivos objeto (.o)
- UUtiles.o
- USensor.o
- Uprincipal.o
- UPresentacion.o
- UPreferencias.o
- UFormulas.o
- UEquipo.o
- UDiaJuliano.o
- UDataModule.o
- UConfiguracionInternet.o
- UConexionesRemotas.o
- UConexiones.o
- UConexionAuto.o
- UCalculoParam.o
- PuertoSerie.o
- Mercury.o
- (además muchos `.o` en `lib\x86_64-win64\`)

### 6) Ejecutables (.exe)
- Mercury.exe
- Mercury_new.exe
- Mercury_9k6.exe
- Copias en `Output\` y `lib\x86_64-win64\` (p. ej. `Output\Mercury.exe`)

## Recomendación para `.gitignore`
Agregar estas líneas al `.gitignore` en la raíz del proyecto:

```
# Artefactos de compilación
*.dcu
*.ppu
*.o
*.exe

# Diagramas / IDE
*.ddp

# Backups temporales
*~
*.~pas
*.~dfm

# Carpetas de build
Output/
lib/

# Otros
*.stackdump
```

## Nota sobre archivado histórico
Si querés conservar los `.ddp` por historial (snapshot único), crear un zip y guardarlo en `_historico/` es razonable: por ejemplo `_historico/Mercury-diagramas-backup-2025-11-11.zip`. Si planeás actualizar ese zip frecuentemente, considerar `git-lfs` o usar Releases/almacenamiento externo.

---

Archivo generado automáticamente por el asistente el 2025-11-11 para documentación interna.
