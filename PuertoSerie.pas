unit PuertoSerie;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Registry, Classes, SysUtils, Dialogs, StdCtrls, SyncObjs, Math,
  Windows, USensor, UUtiles, UFormulas;

const
  // Constantes para funciones de archivo Win32
  GENERIC_READ = $80000000;
  GENERIC_WRITE = $40000000;
  OPEN_EXISTING = 3;
  FILE_ATTRIBUTE_NORMAL = $80;
  INVALID_HANDLE_VALUE = THandle(-1);
  
  // Constantes para DCB
  NOPARITY = 0;
  ODDPARITY = 1;
  EVENPARITY = 2;
  MARKPARITY = 3;
  SPACEPARITY = 4;
  
  ONESTOPBIT = 0;
  ONE5STOPBITS = 1;
  TWOSTOPBITS = 2;

type
  TAbytes = array [0..3] of byte;

// Declaraciones de funciones de la API de Windows para comunicación serial
function CreateFile(lpFileName: PChar; dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: Pointer; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle; stdcall; external 'kernel32.dll' name 'CreateFileA';
function SetupComm(hFile: THandle; dwInQueue, dwOutQueue: DWORD): BOOL; stdcall; external 'kernel32.dll';
function GetCommState(hFile: THandle; var lpDCB: Windows.TDCB): BOOL; stdcall; external 'kernel32.dll';
function SetCommState(hFile: THandle; const lpDCB: Windows.TDCB): BOOL; stdcall; external 'kernel32.dll';
function SetCommTimeouts(hFile: THandle; const lpCommTimeouts: Windows.TCOMMTIMEOUTS): BOOL; stdcall; external 'kernel32.dll';
function BuildCommDCB(lpDef: PChar; var lpDCB: Windows.TDCB): BOOL; stdcall; external 'kernel32.dll' name 'BuildCommDCBA';

type
  TPuertoSerie = class(Tobject)
    private
      DeviceName   : array[0..80] of Char;
      ComFile      : THandle;
      PserieOpen   : boolean;

    public
      RxBufferSize : dword;
      TxBufferSize : dword;
      RxTimeout    : dword;
      TxTimeout    : dword;
      RxBuffer     : string;
      TxBuffer     : string;
      ListaPorts   : Tstrings;
      Baud         : string;
      Parity       : string;
      Data         : string;
      Stop         : string;

      constructor  Crear;
      destructor   Destruir;
      function     CrearListaPuertosSerie(): boolean;
      function     AbrirPuertoSerie(CommPort :string):boolean;
      function     ConfigPuertoSerie():boolean;
      function     EscribirAlPuertoSerie(chs :string): boolean;
      function     LeerDelPuertoSerie(var chs :string; TamBuffer: integer):boolean;
      procedure    CerrarPuerto;
  end;

  TThreadComm = class(TThread)
    private
      //
    protected
      procedure   Execute; override;

    public
      pvalorCH        : array of ^integer;
      pCH_conf        : array of ^byte;

      // Info que leo del equipo
      pNombre         : ^string;
      pHoraEquipo     : ^Tdatetime;
      pHoraActual     : ^Tdatetime;
      pIniMuestreo    : ^Tdatetime;
      pTmuestreo      : ^integer;
      pMemoria        : ^integer;
      pCantMemory     : ^integer;
      pProgreso       : ^integer;
      pASensor        : ^TASensor;          // Puntero al arreglo de canales
      pCalcParam      : ^TCalculoParam;     // Puntero al arreglo de los calculos de Parametros

      // Info que voy a grabar en el equipo
      Hora00          : byte;
      Hora01          : byte;
      Hora02          : byte;
      Hora03          : byte;
      IniMuest00      : byte;
      IniMuest01      : byte;
      IniMuest02      : byte;
      IniMuest03      : byte;
      T00             : byte;
      T01             : byte;
      Tregre00        : byte;
      Tregre01        : byte;
      ConfigCHs       : array of byte;

      // Config de Internet - Info que voy a grabar en el equipo
      gateway         : string;
      user            : string;
      pass            : string;
      server          : string;
      port            : string;
      IndexTConect    : byte;

      // Objeto que maneja el Puerto Serie
      PSerie          : TPuertoSerie;

      T               : integer;           // Periodo de muestreo en SEGUNDOS
      NombreEquipo    : string;            // Nombre del Equipo
      Hora_Base       : string;
      ConfigEquipo    : boolean;
      ConfigInternetEquipo : boolean;     
      DescargarDatos  : boolean;
      ONLine          : boolean;
      CantCanales     : byte;
      Archivo         : string;            // Path y nombre del archivo en que guardo los datos
      sep             : string;            // Caracter que uso para separar las columas cuando bajo datos
      Datos           : Tstrings;          // Información recopilada por el equipo
      FormatoDescarga : byte;              // Elección del Formato en que descargo los datos
      //FormatoFecha    : string;            // Elección del Formato de las fechas los datos
      IndiceFormatoFe : byte;              // Selección del Formato de las fechas
      pActualizar     : TNotifyEvent;      // Actualiza los datos del equipo
      pActualProgres  : TNotifyEvent;      // Actualiza la barra de progreso para la descarga
      POnConectRemoto : TNotifyEvent;      // Realiza algún proceso cuando se CONECTA en forma remoto
      POnDesConRemoto : TNotifyEvent;      // Realiza algún proceso cuando se DESCONECTA en forma remoto

      // Comunicación remota
      ConexOK         : boolean;           // Me indica si establecí alguna conexión remota
      ThTipoCom       : byte;

      // Comunicación Telefonica (Puerto Serie)
      ConecTelef       : boolean;
      DesConecTelef    : boolean;
      IniConecTelef    : boolean; 
      AutoDesconecDesc : boolean;          // Una vez terminadas la descarga se desconecta automaticamente
      AutoDesconecConf : boolean;          // Una vez terminadas la config se desconecta automaticamente
      Ntelefono        : string;           // Número de telefono al cual llama para conectarse
      NombreConex      : string;           // Nombre de la conexión remota      

      constructor crear(CreateSuspended: Boolean; NCanales:byte);
      destructor  Destruir;
      procedure   LeerConfig;
      procedure   EscribirConfig;
      procedure   EscribirConfigInternet;
      procedure   DescargarLosDatos;      
      procedure   LeerDatos;
      procedure   ConectarTelefon;        // Inicia el protocolo de Conección
      procedure   DesConectarTelefon;     // Corta la comunicación telefonica
      procedure   IniComTelefon;          // Inicializa el Hardware de la comunicación telefonica
      function    CalcPeriodoConect(index: byte):integer;
  end;

  // Funciones y Procedimientos de uso generales
  Procedure Retardo(tiempo:integer);
  function  NumToAbytes(num : longint):TAbytes;

implementation


////////////////////////////////////////////////////////////////////////////////
//TPuertoSerie
////////////////////////////////////////////////////////////////////////////////
constructor TPuertoSerie.Crear;
begin
  RxBufferSize := 256;
  TxBufferSize := 256;
  RxTimeout    := 0;
  TxTimeout    := 0;
  DeviceName   := 'COM1';
  Baud         := '9600';
  Parity       := 'n';
  Data         := '8';
  Stop         := '1';
  PserieOpen   := false;

  ListaPorts   := Tstringlist.Create;
end;

////////////////////////////////////////////////////////////////////////////////
destructor  TPuertoSerie.Destruir;
begin
  ListaPorts.Free;
  CerrarPuerto;
end;

////////////////////////////////////////////////////////////////////////////////
function TPuertoSerie.CrearListaPuertosSerie(): boolean;
var
  i:integer;

begin
  ListaPorts.Clear;
  with TRegistry.create do begin
    try
      rootkey:=HKEY_LOCAL_MACHINE;
      if openkey('HARDWARE\DEVICEMAP\SERIALCOMM',false) then begin
        GetValueNames(ListaPorts);
        for i:=0 to ListaPorts.count-1 do
          ListaPorts[i] := ReadString(ListaPorts[i]);
        result := false;
      end
      else result := false;
    finally free;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TPuertoSerie.AbrirPuertoSerie(CommPort :string):boolean;
begin
  StrPCopy(DeviceName, CommPort);
  ComFile := CreateFile(DeviceName,
                        GENERIC_READ or GENERIC_WRITE,
                        0, Nil,
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_NORMAL, 0);

  if ComFile = INVALID_HANDLE_VALUE then begin
    ShowMessage('No se puede acceder al '+ CommPort);
    result := false;
    exit;
  end;

  PserieOpen := true;
  result     := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TPuertoSerie.ConfigPuertoSerie():boolean;
var
  DCB          : Windows.TDCB;
  CommTimeouts : Windows.TCOMMTIMEOUTS;
  Config       : string;
//  ConfigCom    : TCOMMCONFIG;

begin
  if not SetupComm(ComFile, RxBufferSize, TxBufferSize) then  begin
    result := false;
    exit;
  end;

  if not GetCommState(ComFile, DCB) then begin
    result := false;
    exit;
  end;

  //Config := 'baud=9600 parity=n data=8 stop=1';
  Config := 'baud='+Baud+' parity='+Parity+' data='+Data+' stop='+Stop;
  {
  // Modo Binary
    DCB.fBinary=True;

  // RTS control de flujo
    //DCB.fRtsControl := RTS_CONTROL_ENABLE;
    DCB.fRtsControl := RTS_CONTROL_DISABLE;

  // CTS control de flujo
    //DCB.fOutxCtsFlow := true;
    DCB.fOutxCtsFlow := false;

  // DTR control de flujo
    //DCB.fDtrControl := DTR_CONTROL_ENABLE;
    DCB.fDtrControl := DTR_CONTROL_DISABLE;

  // DSR control de flujo
    //DCB.fOutxDsrFlow := true;
    DCB.fOutxDsrFlow := false;

  // DSR sensado
    //DCB.fDsrSensitivity := false;
    DCB.fDsrSensitivity := true;
  }
  if not BuildCommDCB(@Config[1], DCB) then begin
    result := false;
    exit;
  end;

{  DCB.BaudRate := CBR_19200; //CBR_9600	; //CBR_57600;
  DCB.ByteSize := 8;
  DCB.Parity := NOPARITY;
  DCB.StopBits := ONESTOPBIT;}

{  Config := 'COM1';
  if not CommConfigDialog(@Config[1],0,@ConfigCom) then begin
    result := false;
    exit;
  end;}

  if not SetCommState(ComFile, DCB) then begin
    result := false;
    exit;
  end;

  with CommTimeouts do  begin
    ReadIntervalTimeout         := 0;
    ReadTotalTimeoutMultiplier  := 0;
    ReadTotalTimeoutConstant    := RxTimeout;//1000;
    WriteTotalTimeoutMultiplier := 0;
    WriteTotalTimeoutConstant   := TxTimeout;//1000;
  end;

  if not SetCommTimeouts(ComFile, CommTimeouts) then begin
    result := false;
    exit;
  end;

  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TPuertoSerie.EscribirAlPuertoSerie(chs :string): boolean;
var
  BytesEscritos : dword;

begin
  if not WriteFile(ComFile, chs[1], Length(chs), BytesEscritos, Nil) then begin
    result := false;
    exit;
  end;

  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TPuertoSerie.LeerDelPuertoSerie(var chs :string; TamBuffer: integer): boolean;
var
   d            : array[1..256] of Char; //Buffer de lectura
   BytesLeidos  : dword;
   i            : Integer;

begin
  if (TamBuffer > length(d)) then TamBuffer := length(d);
  
  if not ReadFile(ComFile, d, TamBuffer, BytesLeidos, nil) then begin
    result := false;
    exit;
  end;

  chs := '';
  for i := 1 to BytesLeidos do chs := chs + d[i];

//  FlushFileBuffers(ComFile);
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TPuertoSerie.CerrarPuerto;
begin
  if PSerieOpen then FileClose(ComFile); { *Convertido desde CloseHandle* }
  PSerieOpen := false;
end;

////////////////////////////////////////////////////////////////////////////////
//TThreadComm
////////////////////////////////////////////////////////////////////////////////
constructor TThreadComm.crear(CreateSuspended: Boolean; NCanales:byte);
begin
  inherited Create(CreateSuspended);
  Priority        := tpNormal;
  FreeOnTerminate := true;
  PSerie          := TPuertoSerie.Crear;
  Datos           := TStringList.Create;

  ConfigEquipo    := false;
  DescargarDatos  := false;
  Hora_Base       := '01/01/2000 12:00 am';
  ONLine          := false;
  Archivo         := 'NoNombre.txt';
  sep             := #9;
  pActualizar     := nil;
  pActualProgres  := nil;
  POnConectRemoto := nil;
  POnDesConRemoto := nil;
  CantCanales     := NCanales;
  SetLength(pvalorCH ,NCanales);
  SetLength(pCH_conf ,NCanales);
  SetLength(ConfigCHs,NCanales);

  // Tipo de comunicación
  ThTipoCom        := 0;             // Directa por cable serie

  // Comunicación Telefonica
  ConecTelef       := false;
  DesConecTelef    := false;
  IniConecTelef    := false;
  AutoDesconecDesc := false;         // Una vez terminadas la descarga se desconecta automaticamente
  AutoDesconecConf := false;         // Una vez terminadas la config se desconecta automaticamente
  Ntelefono        := '';            // Número de telefono al cual llama para conectarse
  NombreConex      := '';            // Nombre de la conexión remota
end;

////////////////////////////////////////////////////////////////////////////////
destructor TThreadComm.destruir;
begin
  // Me aseguro que no entre a ninguna función
  ConfigEquipo    := false;
  DescargarDatos  := false;

  // Destruyo los objetos
  Pserie.Destruir;
  Datos.Destroy;

  // Libero la memoria de los arreglos dinámicos
  SetLength(pvalorCH ,0);
  SetLength(pCH_conf ,0);
  SetLength(ConfigCHs,0);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.Execute;
var
  auxStr  : string;

begin
  ConexOK := false;

  // Inicializo el sistema de trandmisión por Telefonia Celular
  if (ThTipoCom = 1) then begin
    IniComTelefon;
    retardo(500);   // Espero 1/2seg hasta que se inicialize
  end;

  while not Terminated do begin
    try
      // Conexión por Telefónica (Puerto Serie)
      if (ThTipoCom = 1) then begin
        if ConecTelef then begin
          // Ejecuto el procedure que realiza cosas cuando me conecto
          POnConectRemoto(nil);

          ConecTelef    := false;
          DesConecTelef := false;

          // Me indica si establecí alguna conexión remota
          ConexOK       := true;

          // Inicia la conección telefónica
          ConectarTelefon;

          // Espero 15seg hasta que se conecte
          retardo(15000);
        end;

        // Termina la conección telefónica
        if DesConecTelef  and ConexOK then begin
          // Ejecuto el procedure que realiza cosas cuando me desconecto
          POnDesConRemoto(nil);

          // Acutalizo el flag
          DesConecTelef := false;

          // Inicia la Desconección telefónica
          DesConectarTelefon;

          // Espero 1seg hasta que se Desconecte
          retardo(1000);

          // Me aseguro que no haga nada una vez desconectado
          ONLine           := false;
          ConfigEquipo     := false;
          DescargarDatos   := false;
          AutoDesconecDesc := false;
          AutoDesconecConf := false;
          ConexOK          := false;
        end;

        // Resetea el hardware de la conección telefónica
        if IniConecTelef  then begin
          // Resetea el hardware de la conección telefónica
          IniComTelefon;
          // Me aseguro que no entre mas al ciclo
          IniConecTelef := false;
        end;
      end;

      // Conexión por Internet (TCP/IP)
      if (ThTipoCom = 2) then begin
        //
      end;

      // Indico al equipo que esta conectado a la PC
      if not ONLine then PSerie.EscribirAlPuertoSerie('X');
      auxStr := '';
      if PSerie.LeerDelPuertoSerie(auxStr,2) then begin
        if (auxStr = 'CE') then begin
          LeerConfig;                         // Leeo toda la config del equipo
          PSerie.EscribirAlPuertoSerie('X');  // Indico al equipo que esta conectado a la PC
          ONLine := true;
        end
        else begin
          ONLine        := false;
          DesConecTelef := true;              // Si se pierde la comunicación me desconecto
        end;
      end;
      pActualizar(Self);                      // Actualizo la info en pantalla

      // Configuro las variables básicas del Equipo
      if ConfigEquipo  and ONLine then begin
        EscribirConfig;
        ConfigEquipo := false;
      end;

      // Configuro las variables de internet del Equipo
      if ConfigInternetEquipo  and ONLine then begin
        EscribirConfigInternet;
        ConfigInternetEquipo := false;
      end;

      // Descargo los datos almacenado en la memoria del Equipo 
      if DescargarDatos and ONLine then begin
        DescargarDatos := false;
        DescargarLosDatos;                   // Procedimiento que guarda los datos en el disco con cierto formato
      end;
    except
      Mercury.Configurar := false;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.LeerConfig;
var
  NCanal   : byte;
  numDate  : double;
  num      : integer;
  FechaINI : double;
  auxStr   : string;
  i        : byte;

  //au       : Tstrings;

begin
  auxStr := '';
  if not PSerie.LeerDelPuertoSerie(auxStr,50) then exit;

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

  // guardo la config en el disco
{  au := TStringList.Create;
  for i:=0 to length(auxStr) do au.Add(IntToStr(byte(auxStr[i])));
  au.SaveToFile('d:\logConf.txt');
  au.Destroy;}
end;

////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.EscribirConfig;
var
  auxStr  : string;
  hora    : longint;
  Abytes  : TAbytes;
  HoraAux : double;
  i       : integer;
  Tt      : integer;   // Periodo auxiliar de muestreo

begin
  // Calculos de los Valores Nuevos de Configuración //

  // Nueva hora del Equipo la paso a un formato de 4 bytes
  hora   := round((now-StrToDateTime(Hora_Base))*86400);
  ABytes := NumToAbytes(hora);
  Hora00 := Abytes[0];
  Hora01 := Abytes[1];
  Hora02 := Abytes[2];
  Hora03 := Abytes[3];

  // Cálculo la hora del inicio de muestreo
  if (T<60) then Tt := 60 else Tt := T;
  HoraAux := trunc(now*24)/24;
  while (HoraAux <= (now + 2/86400)) do begin
    HoraAux := HoraAux + Tt/86400; // Paso el T a Días para poder Sumar con la Fecha Actual
  end;
  ABytes := NumToAbytes( round((HoraAux-StrToDateTime(Hora_Base))*86400) );
  IniMuest00 := Abytes[0];
  IniMuest01 := Abytes[1];
  IniMuest02 := Abytes[2];
  IniMuest03 := Abytes[3];

  // Cálculo del nuevo periodo de muestreo
  ABytes := NumToAbytes(T);
  T00    := ABytes[0];
  T01    := ABytes[1];

  // Calculo la cuenta regresiva para muestrear
  ABytes := NumToAbytes( round((HoraAux-now)*86400) );
  Tregre00 := ABytes[0];
  Tregre01 := ABytes[1];


  //--------------------------------------------------------------------------//
  // Escribo el codigo para que entre a la subrrutina
  if not PSerie.EscribirAlPuertoSerie('CE') then exit;

{  // Espero la señal que indica que esta listo para recibir la nueva config
  if not PSerie.LeerDelPuertoSerie(auxStr,2) then exit;
  Retardo(20);}

  // Espero la señal ("OK") que indica que esta listo para recibir la nueva config
  i      := 0;
  auxStr := '';
  while ((auxStr <> 'OK') and (i<=200)) do begin
    if not PSerie.LeerDelPuertoSerie(auxStr,2) then break;
    inc(i,1);
  end;

  // Me aseguro que si hay problemas aborto
  if (i>200) then exit;

  // Escribo la nueva hora al equipo
  PSerie.EscribirAlPuertoSerie(chr(Hora00));
  PSerie.EscribirAlPuertoSerie(chr(Hora01));
  PSerie.EscribirAlPuertoSerie(chr(Hora02));
  PSerie.EscribirAlPuertoSerie(chr(Hora03));

  // Escribo la nueva hora de inicio del muestreo
  PSerie.EscribirAlPuertoSerie(chr(IniMuest00));
  PSerie.EscribirAlPuertoSerie(chr(IniMuest01));
  PSerie.EscribirAlPuertoSerie(chr(IniMuest02));
  PSerie.EscribirAlPuertoSerie(chr(IniMuest03));

  // Escribo el nuevo periodo de muestreo
  PSerie.EscribirAlPuertoSerie(chr(T00));
  PSerie.EscribirAlPuertoSerie(chr(T01));

  // Escribo la Cuenta regresiva para muestrear
  PSerie.EscribirAlPuertoSerie(chr(Tregre00));
  PSerie.EscribirAlPuertoSerie(chr(Tregre01));

  // Escribo la nueva configuración de cada canal
  for i:=0 to length(ConfigCHs)-1 do
    PSerie.EscribirAlPuertoSerie(chr(ConfigCHs[i]));

  // Escribo el Nombre del Equipo
  PSerie.EscribirAlPuertoSerie(NombreEquipo[1]);
  PSerie.EscribirAlPuertoSerie(NombreEquipo[2]);
  PSerie.EscribirAlPuertoSerie(NombreEquipo[3]);
  PSerie.EscribirAlPuertoSerie(NombreEquipo[4]);

  if AutoDesconecConf then DesConecTelef := true;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.DescargarLosDatos;
var
  i          : byte;
  lineaAux1  : string;
  lineaAux2  : string;

begin
  // Configuro las varables para adaptar la descarga con el formato elegido
  case FormatoDescarga of
    0 : begin //Texto (delimitado por tabulaciones)
          sep        := #9;
          Archivo    := Archivo +'.txt';
        end;

    1 : begin //CSV - Planilla de cálculo (formato en español)
          sep        := ';';
          Archivo    := Archivo +'.csv';
        end;

    2 : begin //CSV - Planilla de cálculo (formato en ingles)
          sep        := ',';
          Archivo    := Archivo +'.csv';
        end;

    3 : begin //Página Web
          sep        := #9;
          Archivo    := Archivo +'.txt';
        end;
  end;

  // Configuro las varable para adaptar la fecha con el formato elegido
  //FormatoFecha := Mercury.ObtenerFormatoFecha(IndiceFormatoFe);
  
  // Me aseguro que no alla ningún dato previo
  Datos.Clear;

  // Incorporo la info en el archivo de texto y los titulos
  with Datos do begin
    Add('Datos Generales');
    Add('--------------------------');
    Add('Nombre del Equipo '  +sep+': '+ pNombre^);
    Add('Intervalo de Captura'+sep+': '+ Mercury.GenerarStrTmuest(pTmuestreo^)); //FloatToStr(pTmuestreo^ div 60)+' min');
    Add('Hora del Equipo   '  +sep+': '+ Mercury.GenerarStringFecha(IndiceFormatoFe, pHoraEquipo^));//FormatDateTime(FormatoFecha, pHoraEquipo^));
    Add('Hora de la PC     '  +sep+': '+ Mercury.GenerarStringFecha(IndiceFormatoFe, pHoraActual^)); //FormatDateTime(FormatoFecha, pHoraActual^));
    Add('');
    Add('');

    // Descripción de los canales
    Add('Descripción de los Canales');
    Add('--------------------------');

    for i:=0 to length(pCH_conf)-1 do begin
      if (pCH_conf[i]^ > 0) then begin
        Add('CH '+IntToStr(i)+sep+': '+ pASensor^[i].Descripcion +
            ' ' + '[' + pASensor^[i].Unidad+']');
      end;
    end;
    Add('');
    Add('');


    // Descripción de los valores calculados
    Add('Valores Calculados');
    Add('--------------------------');

    for i:=0 to pCalcParam^.CantParm-1 do begin
      if (pCalcParam^.Parametros[i].Calcular = 1) then begin
        Add('VC '+IntToStr(i)+sep+': '+ pCalcParam^.Parametros[i].Descripcion +
            ' ' + '[' + pCalcParam^.Parametros[i].Unidad+']');
      end;       
    end;
    Add('');
    Add('');

    // Titulos de la tabla de los valores de los canales y los valores Calculados
    lineaAux1 := 'Fecha y Hora           ' + sep;
    lineaAux2 := '-----------------------' + sep;

    // Titulos de la tabla de los valores de los canales
    for i:=0 to length(pCH_conf)-1 do begin
      if (pCH_conf[i]^ > 0) then begin
        lineaAux1 := lineaAux1 + 'CH ' + IntToStr(i) + sep;
        lineaAux2 := lineaAux2 + '----' + sep;
      end;
    end;

    // Titulos de la tabla de los valores Calculados
    for i:=0 to pCalcParam^.CantParm-1 do begin
      if (pCalcParam^.Parametros[i].Calcular = 1) then begin
        lineaAux1 := lineaAux1 + 'VC ' + IntToStr(i) + sep;
        lineaAux2 := lineaAux2 + '----' + sep;
      end;
    end;

    Add(lineaAux1);
    Add(lineaAux2);
  end;

  // Leo los datos del equipo
  LeerDatos;

  // Me desconecto de la conexión remota
  if AutoDesconecDesc then DesConecTelef := true;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.LeerDatos;
var
  auxStr     : string;
  Nbytes     : LongInt;
  i,j,k      : LongInt;
  linea      : string;
  num        : integer;
  progresoOLD: integer; 
  NCanal     : byte;
  MaxCanales : byte;
  IniMuestr  : double;
  periodo    : real;
  Nlineas    : integer;
  CanalesAct : array of byte;

begin
  Nbytes     := pMemoria^;
  IniMuestr  := pIniMuestreo^;
  periodo    := (pTmuestreo^);

  // Periodo de muestreo de 500 mseg.
  if (periodo = 0) then periodo := Tmin;  

  // Analiso cual son los canales activos
  SetLength(CanalesAct,0);
  for i:=0 to CantCanales-1 do begin
    if (pASensor^[i].Config > 0) then begin
      SetLength(CanalesAct,length(CanalesAct)+1);
      CanalesAct[length(CanalesAct)-1] := i;
    end;
  end;
  MaxCanales := length(CanalesAct);

  if (MaxCanales > 0) and (Nbytes > 4)then begin
    // Escribo el codigo para que entre a la subrrutina ("L"eer "D"atos)
    if not PSerie.EscribirAlPuertoSerie('LD') then exit;

    // Espero que me envie el equipo el codigo "DG" Datos Guardados, para Sincronizar
    i      := 0;
    auxStr := '';
    while ((auxStr <> 'DG') and (i<=200)) do begin
      if not PSerie.LeerDelPuertoSerie(auxStr,2) then break;
      inc(i,1);
    end;

    // Me aseguro que si hay problemas aborto
    if (i>200) then exit;

    // Inicializo el Progreso
    progresoOLD := 0;
    pProgreso^  := 0;
    pActualProgres(self);

    // Leo los Datos
    NCanal  := 0;
    Linea   := '';
    Nlineas := 0;

    // Estos primeros 4 datos son la cantidad de memoria ocupada, no le doy importancia
    PSerie.LeerDelPuertoSerie(auxStr,2);
    PSerie.LeerDelPuertoSerie(auxStr,2);
    
    for i:=3 to (Nbytes div 2) do begin
      auxStr := '';
      if not PSerie.LeerDelPuertoSerie(auxStr,2) then break;

      num := Byte(auxStr[1])+Byte(auxStr[2])+Byte(auxStr[2])*255;
      pASensor^[CanalesAct[NCanal]].ComputarValor(num);

      if length(Linea)>0 then Linea := Linea + sep + pASensor^[CanalesAct[NCanal]].ValorReal
      else Linea := pASensor^[CanalesAct[NCanal]].ValorReal;

      inc(NCanal,1);
      if (NCanal > MaxCanales-1) then begin
        // Computo el valor de los parametros a calcular, salinidad, densidad...
        for j:=0 to pCalcParam^.CantParm-1 do begin
          with pCalcParam^.Parametros[j] do begin
            if (Calcular = 1) then begin
              // Cargo la info de los valores de entrada temp, cond, profundidad...
              for k:=0 to Nparam-1 do begin
                if (AParam[k].canal >= 0) then AParam[k].valor := pASensor^[AParam[k].canal].ValorNum
                else AParam[k].valor := 0;
              end;

              // Calculo los parámetros salinidad, densidad.....
              pCalcParam^.CalcularValorParam(j);

              // Incorporo la info del parametro calculado a la linea
              Linea := Linea + sep + ResultCalcStr;
            end;
          end;
        end;

        // Incorporo la linea a la info total, que se guarda en el archivo
        Datos.Add(Mercury.GenerarStringFecha(IndiceFormatoFe,IniMuestr+Nlineas*(periodo/86400))+sep+Linea);
        NCanal := 0;
        Linea  := '';
        inc(NLineas,1);
      end;

      //pProgreso^ := trunc(((2*i)/Nbytes)*100);
      pProgreso^ := 2*i;
      if not (pProgreso^ = progresoOLD) then  pActualProgres(self);
      progresoOLD := pProgreso^;
    end;

    try
        if not FileExists(Archivo) then Datos.SaveToFile(Archivo)
        else if DeleteFile(PChar(Archivo)) then Datos.SaveToFile(Archivo);
    except
        MessageBox(Handle,PChar('No se puede escribir en "'+ Archivo + '".'+
                   #13+'La carpeta no existe o no tiene permiso de escritura.') ,
                   PChar('Descarga'), MB_OK	or MB_ICONINFORMATION );

        // Me aseguro que no borre la memoria automaticamente si hubo problemas  
        Mercury.Configurar := false;
    end;
  end;

  pProgreso^ := 0;
  pActualProgres(self);
  SetLength(CanalesAct,0);
end;

// Comunicación Telefonica (Puerto Serie) 
////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.ConectarTelefon;     // Inicia el protocolo de Conección
begin
  // Escribo el codigo para conectar al equipo
  if not PSerie.EscribirAlPuertoSerie('atd'+Ntelefono+#13) then exit;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.DesConectarTelefon;  // Corta la comunicación telefonica
begin
  // Escribo el codigo para conectar al equipo
  if not PSerie.EscribirAlPuertoSerie('ath'+#13) then exit;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TThreadComm.IniComTelefon; // Inicializa el hardware de la comunicación telefónica
begin
  // Escribo el codigo para resetear el hardware de la comunicación telefónica 
  if not PSerie.EscribirAlPuertoSerie('atz'+#13) then exit;
end;

////////////////////////////////////////////////////////////////////////////////
// Comunicación por Internet (TCP/IP)
procedure TThreadComm.EscribirConfigInternet;
var
  strIni     : string;
  strFin     : string; 
  strGateway : string;
  strServer  : string;
  auxStr     : string;
  Abytes     : TAbytes;
  i          : byte;

begin
  // Genero el String de Inicialización del modem
  strIni := 'ATE0'+#13+'ATE0'+#13+'AT+CMGF=1'+#13+'AT+CNMI=3,2,2,0,0'+#13+'AT+CMGD=1,4'+#13
             +'AT+CREG=1'+#13;

  // Genero el String del gateway   "internet.ctimovil.com.ar","gprs","gprs"
  strGateway := 'AT+MIPCALL=1,"'+gateway+'","'+user+'","'+pass+'"'+#13+'/';

  // Genero el String del server    40000,"168.96.131.146",40000,0
  strServer := 'AT+MIPOPEN=1,'+port+',"'+server+'",'+port+',0'+#13+'/';

  // Genero el String de finalización del modem
  ABytes := NumToAbytes(CalcPeriodoConect(IndexTConect));
  strFin := chr(Abytes[1])+chr(Abytes[0])+'AT+MIPCLOSE=1'+#13+'/'+'AT+MIPCALL=0'+#13+'/';
  //strFin := chr(CalcPeriodoConect(IndexTConect))+'AT+MIPCLOSE=1'+#13+'/'+'AT+MIPCALL=0'+#13+'/';

  // Escribo toda la config de internet
  auxStr := strIni + strGateway + strServer + ';' + strFin + '#';

  PSerie.EscribirAlPuertoSerie('GA');
  for i:=1 to length(auxStr) do begin
    PSerie.EscribirAlPuertoSerie(auxStr[i]);
    retardo(5);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TThreadComm.CalcPeriodoConect(index: byte):integer;
var
  P : integer;
  i : byte;
  N : byte;
  T : real; // Periodo de muestreo en seg.

begin
  N := 0;
  T := pTmuestreo^;
  if (T=0) then T:=Tmin; 

  for i:=0 to length(pvalorCH)-1 do
    if pCH_conf[i]^>0 then inc(N,1);

  case index of
    // Conectar Simpre
    0 : P := 0;
    // Conectar cada 1/2 hora
    1 : P := round(30/(T/60))-1;
    // Conectar cada 1 hora
    2 : P := round(60/(T/60))-1;
    // Conectar cada 2 horas
    3 : P := round(2*60/(T/60))-1;
    // Conectar cada 4 horas
    4 : P := round(4*60/(T/60))-1;
    // Conectar cada 6 horas
    5 : P := round(6*60/(T/60))-1;
    // Conectar cada 8 horas
    6 : P := round(8*60/(T/60))-1;
    // Conectar cada 10 horas
    7 : P := round(10*60/(T/60))-1;
    // Conectar cada 12 horas
    8 : P := round(12*60/(T/60))-1;
    // Conectar cada 24 horas
    9 : P := round(24*60/(T/60))-1;
    // Óptima, minimo costo de comunicación
    10: P := round(980/(N*2)); // 980 son los bytes maximos que meto en un paquete
  else
    P :=0;
  end;

  // Me aseguro que este en rango.
  if P>65535 then P:= 65535;
  if P<0   then P:= 0;

  // Me aseguro que como minimo no se re-conecte en un periodo menor a 10 min.
  if ((T<600) and (P<600/T)) then P:=round(600/T)-1;

  result := P;
end;

////////////////////////////////////////////////////////////////////////////////
// Funciones de Uso Generales //////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
Procedure Retardo(tiempo:integer);
var
  evento : Tevent;
begin
  evento := Tevent.Create(nil,true,false,'');
  evento.WaitFor(tiempo);
  evento.Free;
end;

////////////////////////////////////////////////////////////////////////////////
function NumToAbytes(num : longint):TAbytes;
var
  resto  : byte;
  pos    : byte;
  i,j    : integer;
  Abytes : TAbytes;

begin
  // Inicializo el arreglo;
  for i:=0 to length(Abytes)-1 do Abytes[i] :=0;

  // Si es negativo entonces 0
  if (num < 0) then num := 0;

  // El numero lo paso a un formato de 4 bytes
  pos  := 0;
  for i:=0 to 8*length(Abytes)-1 do begin
    j         := i div 8;
    resto     := num mod 2;
    num       := num div 2;
    Abytes[j] := Abytes[j]+ trunc(resto*power(2,pos));

    inc(pos,1);
    if pos>7 then pos := 0;
  end;
  Abytes[j] := Abytes[j]+ trunc(num*power(2,7));

  result := Abytes;
end;

end.