# Migración del Mercury de Delphi a Lazarus

## Cosas que cambié y que me falta hacer

---

## Lo que cambié hasta ahora

### Archivo principal del proyecto

Con la herramienta de migracion de Delphi a Lazarus:
Cambié `Mercury.dpr` por `Mercury.lpr` y agregué:

- `{$MODE Delphi}` para que compile igual que antes
- `Interfaces` en los uses
- Comenté algunas units que dan problemas:
  - UGrafico - necesita TeeChart
  - UOpciones3D - componentes 3D que no tengo
  - UColor - selector de colores
  - UServerSocket y UEquipoInternet - sockets que hay que cambiar

### Los archivos .pas

Por suerte no tuve que tocar casi nada porque puse `{$MODE Delphi}` y funciona todo igual.

## Qué funciona y qué no

### Lo que anda perfecto

- TStringList, TThread, TRegistry - todo igual que en Delphi
- Los formularios principales - sin problemas
- La comunicación serie - funciona tal cual
- Los DataModules - sin cambios

### Lo que tuve que dejar para después

- \*_Gráficos_ - necesito instalar TeeChart para Lazarus
- **3D** - no sé bien qué usar todavía
- **Sockets** - tengo que cambiar ScktComp por algo de Lazarus (Synapse capaz)

---

## La comunicación serie - e

El puerto serie funciona igual que antes. Como uso directamente la API de Windows (CreateFile, ReadFile, WriteFile) no tuve que cambiar nada.

Sigue funcionando:

- Listar puertos COM
- Configurar velocidad, paridad, bits, etc.
- Leer y escribir datos

## Los threads también andan bien

El TThreadComm que maneja la comunicación funciona igual:

- Comunicación por cable serie
- Comunicación telefónica (módem)
- Comunicación por internet - esto lo tengo que arreglar después

---

## Los formularios

### Los que ya funcionan

- Formulario principal
- Pantalla de bienvenida
- Configuraciones y preferencias
- Cálculo de parámetros
- Conexiones remotas y automáticas
- Configuración de internet

### Los que dejé comentados por ahora

- UGrafico.pas - los gráficos
- UOpciones3D.pas - cosas en 3D
- UColor.pas - selector de colores

## Lo que funciona del sistema

### Ya está andando

- Me conecto a los equipos por puerto serie
- Leo la configuración de los equipos
- Bajo los datos que tienen guardados
- Configuro los equipos remotamente
- Manejo los sensores y sus canales
- Calculo salinidad, densidad y esas cosas
- Exporto a TXT, CSV (en español y inglés)
- La comunicación telefónica con módems

### Me falta hacer

- Los gráficos en tiempo real y históricos
- La parte 3D (si la llego a necesitar)
- La comunicación por TCP/IP

---

## Archivos del proyecto

Lazarus me creó:

- Mercury.lpi - el proyecto
- Mercury.lps - configuraciones
- Mercury.lpr - el programa principal

Los .ini y .cfg los mantuve igual.

## Qué librerías uso

### Las que funcionan igual

- Windows.pas - API de Windows
- Registry.pas - registro de Windows
- SyncObjs.pas - threads y eso

### Las que tengo que cambiar

- ScktComp.pas - sockets de Delphi (cambiar por Synapse)
- TeeChart - gráficos (instalar para Lazarus)

## Problemas que tuve y resolví

### Ya arreglé

- Poner `{$MODE Delphi}` y listo, casi todo funcionó igual
- Los tipos de datos iguales
- La API de Windows funciona igual
- Los threads andan igual
- El registro de Windows también

### Lo que me falta arreglar

- Instalar los componentes que necesito para Lazarus
- Cambiar los sockets por algo compatible
- Ver si instalo TeeChart o uso otra cosa para gráficos

---

## Lo que tengo que hacer todavía

### Urgente

1. **Instalar TeeChart para Lazarus** para que anden los gráficos
2. **Cambiar los sockets** - probar Synapse que dicen que es fácil

### Cuando tenga tiempo

1. **Los componentes 3D** - capaz uso OpenGL o algo así
2. **El selector de colores** - por ahora uso el TColorDialog común

### Si me sobra tiempo

1. **Mejorar la interfaz**
2. **Documentar mejor el código**

## Configuración que uso

```pascal
{$MODE Delphi}    // Para que compile igual que en Delphi
{$H+}             // Strings largos
{$R *.res}        // Los recursos
```

## Protocolo de comunicación

Mi sistema habla con los equipos así:

- Mando 'X' → el equipo responde 'CE' si está conectado
- Mando 'CE' → entra en modo configuración
- Mando 'LD' → me manda los datos, responde 'DG' cuando está listo

Funciona con:

- Puerto serie de COM1 a COM255
- Velocidades desde 300 hasta 115200 bps
- Formatos 7N1, 8N1, 8E1, 8O1

## Exportación de datos

Puedo guardar en:

- TXT (separado por tabs)
- CSV español (separado por ;)
- CSV inglés (separado por ,)

---

## En resumen

**Lo que anda:** todo lo importante funciona  
**Lo que falta:** Principalmente gráficos y la parte de red por TCP/IP

**Lo mejor:** La comunicación serie y los equipos funcionan igual que antes

**Lo que sigue:** Instalar TeeChart y arreglar los sockets, después está listo.
