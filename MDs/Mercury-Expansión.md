# Expansión de Mercury

## Archivos afectados por la cantidad de Sensores

### 1. Uprincipal.pas . Inicialización del Equipo

La cantidad de canales está hardcodeada en 10 al crear el objeto TEquipo: Uprincipal.pas:504. La condición de creación es que la comnicación sea distinta a 2. 
```` pas
  // Creo y Configuro el Equipo con 10 canales si es necesario por el tipo de Comunicación
  if (Mercury.TipoDeComm <> 2) then begin
    Equipo                           := TEquipo.crear(10,Mercury.PuertoSerie, Mercury.TipoDeComm);
    Equipo.ThreadComm.pProgreso      := @statusbar.Tag;
    Equipo.ThreadComm.pActualizar    := ActualizarInfo;
    Equipo.ThreadComm.pActualProgres := ActualizarProgreso;
````
TEquipo.Crear: [UEquipo.pas: 48](https://github.com/GuidoMateoBZ/Mercury-1.27/blob/master/UEquipo.pas#50)

