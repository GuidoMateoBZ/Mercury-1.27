# Expansión de Mercury

## Archivos afectados por la cantidad de Sensores

## 1. Uprincipal.pas . Inicialización del Equipo

La cantidad de canales está hardcodeada en 10 al crear el objeto TEquipo: [UEquipo.pas: 504](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/UEquipo.pas#L504). La condición de creación es que la comnicación sea **distinta a 2**. 

```` pas
  // Creo y Configuro el Equipo con 10 canales si es necesario por el tipo de Comunicación
  if (Mercury.TipoDeComm <> 2) then begin
    Equipo                           := TEquipo.crear(10,Mercury.PuertoSerie, Mercury.TipoDeComm);
    Equipo.ThreadComm.pProgreso      := @statusbar.Tag;
    Equipo.ThreadComm.pActualizar    := ActualizarInfo;
    Equipo.ThreadComm.pActualProgres := ActualizarProgreso;
````
TEquipo.Crear: [UEquipo.pas: 48](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/UEquipo.pas#L48)

```` pas
constructor TEquipo.Crear(NCanales:byte; COMM:string; TipoCom: byte);
  ...
  PuertoSerie := COMM;
  NumCanales  := NCanales;
  ...
  // Creo los canales
  SetLength(Canales,NumCanales);
  for i:=0 to NumCanales-1 do Canales[i] := TSensor.Crear;
  ...
  // Creo el Thread suspendido (true)  y lo inicializo
  ThreadComm := TThreadComm.crear(True,NumCanales);

  // Configuro los canales
  for i:=0 to NumCanales-1 do begin
    ThreadComm.pvalorCH[i] := @Canales[i].ValorSensor;
    ThreadComm.pCH_conf[i] := @Canales[i].Config;
  end;

  // Configuro las variables mas importantes y el puerto serie
  with ThreadComm do begin
    ...
    pASensor     := @Canales;
    pCalcParam   := @CalcParam;
    pProgreso    := nil;
    ThTipoCom    := TipoCom;
````

## 2. PuertoSerie.pas - Protocolo de Comunicación CE
A. Tamaño del Buffer de Lectura
---
El comando CE lee 50 bytes del equipo: [PuertoSerie.pas:547](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/PuertoSerie.pas#L548) 

Fórmula para obtener la cantidad de bytes:
````
Nuevos bytes = 2 + (NumSensores × 2) + 26  
````
B. Lectura de Valores de Canales
---
El loop que lee los valores de cada sensor usa `length(pvalorCH)`, por lo que se adapta automáticamente: [PuertoSerie.pas:551-555](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/PuertoSerie.pas#L551)

No requiere cambios porque usa el tamaño dinámico del arreglo.

C. Lectura de Configuración de Canales
---
También usa `length(pvalorCH)`: [PuertoSerie.pas:584-585](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/PuertoSerie.pas#L584)

No requiere cambios porque es dinámico.

D. Posiciones de los Bytes
---
Están ajustados los bytes a mano. Habría que ajustarlos o quizás borrar las asignaciones.

```` pas
  // Obtengo todos los valores de los canales
  i := 1;
  for NCanal:=0 to length(pvalorCH)-1 do begin
    num := Byte(auxStr[i])+Byte(auxStr[i+1])+Byte(auxStr[i+1])*255;
    pvalorCH[NCanal]^ := num;
    inc(i,2);
  end;

// Leeo la Hora del Equipo
  i := 21;
        // Formo el número de la fecha a partir de los 4 Bytes (32 bits)
  numDate := Byte(auxStr[i])+Byte(auxStr[i+1])+ Byte(auxStr[i+2])+Byte(auxStr[i+3])+
             Byte(auxStr[i+1])*255+Byte(auxStr[i+2])*65535+Byte(auxStr[i+3])*16777215;

        //Paso a Días la fecha de numDate que esta en segundos
  numDate := numDate/86400 + StrToDateTime(Hora_Base);
  pHoraEquipo^ := numDate;
  pHoraActual^ := now;

  // Leo la fecha inicial del muestreo
  i := 25;
        // Formo el número de la fecha a partir de los 4 Bytes (32 bits)
  numDate  := Byte(auxStr[i])+Byte(auxStr[i+1])+ Byte(auxStr[i+2])+Byte(auxStr[i+3])+
              Byte(auxStr[i+1])*255+Byte(auxStr[i+2])*65535+Byte(auxStr[i+3])*16777215;
        //Paso a Días la fecha de numDate que esta en segundos
  FechaINI      := numDate/86400 + StrToDateTime(Hora_Base);
  pIniMuestreo^ := FechaINI;

  // Leo el intervalo de muestreo
  i := 29;
  pTmuestreo^ := (Byte(auxStr[i])+Byte(auxStr[i+1])+Byte(auxStr[i+1])*255);


  // Leeo la configuración de los Canales
  i := 33;
  for NCanal:=0 to length(pvalorCH)-1 do
    pCH_conf[NCanal]^ := Byte(auxStr[i+NCanal]);


  // Leo el nombre del Equipo
  i := 43;
  pNombre^ := auxStr[i]+auxStr[i+1]+auxStr[i+2]+auxStr[i+3];

  // Leo la cantidad de memoria ocupada (Numeros de Bytes)
  i := 47;
  pMemoria^ := Byte(auxStr[i])+Byte(auxStr[i+1])+Byte(auxStr[i+2])+Byte(auxStr[i+1])*255+Byte(auxStr[i+2])*65535;

  // Leo la cantidad de memoria que tiene el equipo disponible (Numeros de Bytes)
  i := 50;
  pCantMemory^ := trunc(power(2,Byte(auxStr[i])));
````

## 3. UEquipo.pas - Clase TEquipo
El constructor recibe NCanales como parámetro y crea los arreglos dinámicamente: [UEquipo.pas:82-86](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/UEquipo.pas#L82)

```pas
  // Configuro los canales
  for i:=0 to NumCanales-1 do begin
    ThreadComm.pvalorCH[i] := @Canales[i].ValorSensor;
    ThreadComm.pCH_conf[i] := @Canales[i].Config;
  end;
```

No requiere cambios internos porque usa el parámetro NCanales para dimensionar los arreglos dinámicamente.

Los loops que recorren los canales también son dinámicos: (Limpiar)[UEquipo.pas:167](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/UEquipo.pas#L167), (Guardar Equipo) [UEquipo.pas:186-190](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/UEquipo.pas#L186), (Cargar Equipo)[UEquipo.pas:247-250](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/UEquipo.pas#L247)

## Resumen de Cambios Necesarios
---
- Uprincipal.pas línea 504: Cambiar 10 por el nuevo número de sensores
- PuertoSerie.pas línea 547: Cambiar 50 por el nuevo tamaño calculado
- PuertoSerie.pas líneas 558-598: Ajustar todos los índices i := XX
- UEquipoInternet.pas línea 920: Cambiar 50 por el nuevo tamaño
- UEquipoInternet.pas líneas 932-970: Ajustar los mismos índices que en  PuertoSerie.pas
- Firmware del equipo: Modificar el protocolo CE para enviar más bytes de sensores
