unit UEquipo;

interface
uses
  Windows, Registry, Classes, SysUtils, Dialogs, StdCtrls, SyncObjs, Math,
  UUtiles, PuertoSerie, IniFiles, USensor, UFormulas;

type

  TEquipo = class(Tobject)
    private
      //
    public
      Nombre      : string;                  // Nombre del Equipo
      Memoria     : longint;                 // Cantidad de bytes ocupados de la Memoria
      Hora        : Tdatetime;               // Hora actual del Equipo
      HoraPC      : Tdatetime;               // Hora actual de la PC
      iniMuestr   : Tdatetime;               // Hora en la que se inicio el muestreo
      Tmuestreo   : integer;                 // Periodo de muestreo en SEGUNDOS
      Progreso    : real;                    // Variable que representa el progreso en el proceso sea cual sea
      UsarCH9     : boolean;                 // Me indica que tengo que usar el CH9 en ves del CH8  
      Canales     : TASensor;                // Arreglo que tiene Config y Seteos de cada canal
      ListaSenDir : TASensor;                // Arreglo que tiene la info de los sensores en el dir de equipo
      CalcParam   : TCalculoParam;           // Objeto que permite calcular los param de Salinidad, Densidad .....

      PuertoSerie : string;                  // Puerto serie al que esta conectado el Equipo
      Hora_Base   : string;                  // Hora que tomo como referencia para calcular las fechas del equipo
      NumCanales  : byte;                    // Cantidad de canales que tiene el Equipo
      Vref        : real;                    // Tensión de referencia usada por el A/D
      BitsAD      : integer;                 // Bytes de Resuloción del A/D (8,10,..16)
      CantMemory  : integer;                 // Capacidad de Almacenamiento en Bytes
      Escala      : real;                    // Escala para comvertir los numeros en Volts   
      ThreadComm  : TThreadComm;             // Thread de comunicación con el equipo.  

      constructor Crear(NCanales:byte; COMM:string; TipoCom: byte);
      destructor  Destruir;
      procedure   Limpiar;
      function    GuardarEquipo(DirINI : string):boolean;
      function    CargarEquipo(DirINI : string):boolean;
      function    BorrarEquipo(DirINI : string):boolean;
  end;

implementation

////////////////////////////////////////////////////////////////////////////////
// TEquipo//////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
constructor TEquipo.Crear(NCanales:byte; COMM:string; TipoCom: byte);
var
  i : integer;

begin
  // Inicializo las variables mas importantes
  Nombre      := '    ';
  Memoria     := 0;
  Hora        := now;
  HoraPC      := now;
  iniMuestr   := now;
  Tmuestreo   := 60;
  PuertoSerie := COMM;
  NumCanales  := NCanales;
  Hora_Base   := '01/01/2000 12:00 am';
  Vref        := 5.03;
  BitsAD      := 1024;
  CantMemory  := 32768;  
  Escala      := Vref/BitsAD;
  UsarCH9     := false;

  // Creo los canales
  SetLength(Canales,NumCanales);
  for i:=0 to NumCanales-1 do Canales[i] := TSensor.Crear;

  // Me aseguro que la lista esté vácia
  SetLength(ListaSenDir,0);

  // Creo el objeto TCalcParam
  CalcParam := TCalculoParam.Crear; 

  // Creo el Thread suspendido (true)  y lo inicializo
  ThreadComm := TThreadComm.crear(True,NumCanales);

  // Configuro los canales
  for i:=0 to NumCanales-1 do begin
    ThreadComm.pvalorCH[i] := @Canales[i].ValorSensor;
    ThreadComm.pCH_conf[i] := @Canales[i].Config;
  end;

  // Configuro las variables mas importantes y el puerto serie
  with ThreadComm do begin
    Hora_Base    := Hora_Base;
    pNombre      := @Nombre;
    pHoraEquipo  := @Hora;
    pHoraActual  := @HoraPC;
    pIniMuestreo := @iniMuestr;
    pTmuestreo   := @Tmuestreo;
    pMemoria     := @Memoria;
    pCantMemory  := @CantMemory;
    pASensor     := @Canales;
    pCalcParam   := @CalcParam;
    pProgreso    := nil;
    ThTipoCom    := TipoCom;

    if not Suspended then Suspend;
    PSerie.CerrarPuerto;
    // Baurate por defecto (Cable Serie)
    PSerie.Baud := '19200';

    // Seteo los parámetros para el tipo de Comunicación
    case TipoCom of
      0 : PSerie.Baud := '19200'; // CABLE SERIE
      //0 : PSerie.Baud := '9600'; // CABLE SERIE
      1 : PSerie.Baud := '1200';  // TELEFONIA serie
    else
      PSerie.Baud := '19200'; // CABLE SERIE  
    end;

    PSerie.Data      := '8';
    PSerie.Parity    := 'n';
    PSerie.Stop      := '1';
    PSerie.RxTimeout := 750;//650;
    PSerie.TxTimeout := 0;
    PSerie.AbrirPuertoSerie(PuertoSerie);
    if not PSerie.ConfigPuertoSerie then exit;

    Resume; // Arranco el thread para la comunicación con el equipo
  end;
end;

////////////////////////////////////////////////////////////////////////////////
destructor TEquipo.Destruir;
var
  i : integer;

begin
  // Reseteo el modem por las dudas antes de cerrar el programa
  if (ThreadComm.ThTipoCom = 1) then begin
    // reseteo el modem por las dudas
    ThreadComm.IniConecTelef := true;
    for i:=0 to 3 do begin
      // Espero 1/2 seg hasta que se Desconecte
      retardo(500);
      // Si ya reseteo el hardware de com telefonica salgo 
      if not ThreadComm.IniConecTelef then break;
    end;
  end;

  ThreadComm.Suspend;
  for i:=0 to length(Canales)-1 do Canales[i].Destruir;
  for i:=0 to length(ListaSenDir)-1 do ListaSenDir[i].Destruir;
  setLength(ListaSenDir,0);
  ThreadComm.Terminate;
  SetLength(Canales,0);
  CalcParam.Destruir;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TEquipo.Limpiar;
var
  i : integer;

begin
  Nombre    := '';
  Tmuestreo := 60;
  UsarCH9   := false;
  for i:=0 to NumCanales-1 do Canales[i].Limpiar;
  for i:=0 to length(ListaSenDir)-1 do ListaSenDir[i].Destruir;
  setLength(ListaSenDir,0);
end;

////////////////////////////////////////////////////////////////////////////////
function TEquipo.GuardarEquipo(DirINI : string):boolean;
var
  ArchivoINI   : TIniFile;
  i            : integer;
  PathDir      : string;

begin
  ArchivoINI   := TIniFile.Create(DirINI+'\'+Nombre+'\'+Nombre+'.ini');
  PathDir      := DirINI + '\'+Nombre + '\';

  // Cargo los datos desde el Archivo INI
  try
    // Me aseguro que exista el dir sino lo creo
    if not DirectoryExists(PathDir) then MkDir(PathDir);

    for i:=0 to NumCanales-1 do begin
      ArchivoINI.WriteString(Nombre, 'CH'+intToStr(i)+'_desc', Canales[i].Descripcion);
      ArchivoINI.WriteString(Nombre, 'CH'+intToStr(i)+'_conf', IntToStr(Canales[i].Config));
    end;

    // Guardo la config del los calculos de los parámetros
    CalcParam.GuardarParametros(DirINI+'\'+Nombre+'\'+Nombre+'.ini', Nombre);

    // Pongo el separador de las distintas secciones
    ArchivoINI.WriteString(Nombre, '------', '------');

    // Guardo los sensores en el dir del Equipo
    for i:=0 to NumCanales-1 do begin
      if (not FileExists(PathDir + Canales[i].Nombre + '.sen')) and (Canales[i].Config >1) then
        Canales[i].GuardarEnArchivo(PathDir + Canales[i].Nombre + '.sen');
    end;
  except
    ArchivoINI.Free;
    result := false;
    exit;
  end;


  ArchivoINI.Free;
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TEquipo.CargarEquipo(DirINI : string):boolean;
var
  ArchivoINI   : TIniFile;
  SeccionesINI : TStrings;
  i            : integer;
  AFiles       : AFilesOfDir;
  PathDir      : string;

begin
  SeccionesINI := TStringList.Create;
  ArchivoINI   := TIniFile.Create(DirINI+'\'+Nombre+'\'+Nombre+'.ini');
  PathDir      := DirINI+'\'+Nombre+'\';

  if not FileExists(ArchivoINI.FileName) then begin
    ArchivoINI.Free;
    SeccionesINI.Free;
    result := false;
    exit;
  end;

  SeccionesINI.Clear;
  ArchivoINI.ReadSections(SeccionesINI);

  // Me aseguro que este el equipo en el Archivo INI
  if not ArchivoINI.SectionExists(Nombre) then begin
    ArchivoINI.Free;
    SeccionesINI.Free;
    result := false;
    exit;
  end;

  // Cargo los datos desde el Archivo INI
  try
    for i:=0 to NumCanales-1 do begin
      Canales[i].DescrINI  := ArchivoINI.ReadString(Nombre, 'CH'+intToStr(i)+'_desc'         , '');
      Canales[i].ConfigINI := StrToInt(ArchivoINI.ReadString(Nombre, 'CH'+intToStr(i)+'_conf', '0'));
    end;

    // Cargo  la config del los calculos de los parámetros
    CalcParam.CargarParametros(DirINI+'\'+Nombre+'\'+Nombre+'.ini', Nombre);

    // Obtengo una lista de los archivos de sensores en el dir del equipo
    ExtractFilesOfDir(PathDir + '*.sen', AFiles);
    // Redimenciono el arreglo para la cantidad de Sensores
    SetLength(ListaSenDir, length(AFiles));
    // Cargo los sensores
    for i:=0 to length(AFiles)-1 do begin
      ListaSenDir[i] := TSensor.Crear;
      ListaSenDir[i].CargarDeArchivo(PathDir + AFiles[i].Name);
    end;
  except
    ArchivoINI.Free;
    result := false;
    exit;
  end;

  ArchivoINI.Free;
  SeccionesINI.Free;
  result := true;  
end;

////////////////////////////////////////////////////////////////////////////////
function TEquipo.BorrarEquipo(DirINI : string):boolean;
var
  ArchivoINI   : TIniFile;
  SeccionesINI : TStrings;
//  AFiles       : AFilesOfDir;
//  i            : integer;
//  PathDir      : string;

begin
  SeccionesINI := TStringList.Create;
  ArchivoINI   := TIniFile.Create(DirINI+'\'+Nombre+'\'+Nombre+'.ini');
//  PathDir      := ExtractFilePath(NombreINI)+'\'+Nombre+'\';

  // Me Aseguro que exista el Archivo
  if not FileExists(ArchivoINI.FileName) then begin
    ArchivoINI.Free;
    SeccionesINI.Free;
    result := false;
    exit;
  end;

  SeccionesINI.Clear;
  ArchivoINI.ReadSections(SeccionesINI);

  // Me aseguro que este el equipo en el Archivo INI
  if not ArchivoINI.SectionExists(Nombre) then begin
    ArchivoINI.Free;
    SeccionesINI.Free;
    result := false;
    exit;
  end;

  // Borro la Configuración del Equipo en el Archivo INI
  ArchivoINI.EraseSection(Nombre);

{  // Borro toda la info en el dir del equipo
  if DirectoryExists(PathDir) then begin
    // Obtengo una lista de los archivos en el dir del equipo
    ExtractFilesOfDir(PathDir + '*.*', AFiles);
    // Borro todos los archivos
    for i:=0 to length(AFiles)-1 do DeleteFile(PathDir + AFiles[i].Name);
    // Borro el dir del equipo
    RmDir(PathDir);
  end;}

  ArchivoINI.Free;
  SeccionesINI.Free;
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
end.
