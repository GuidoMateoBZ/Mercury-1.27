unit UConexiones;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, ComCtrls, ImgList, IniFiles;

type
  TConexAuto  = class(Tobject)               // Objeto que administra la conexi�n autom�tica
    private
    //
    public
      intervalo   : byte;                    // Intervalo entre las conexiones autom�ticas 
      CritDesconec: byte;                    // Criterio que utilizo para desconectarme auto
      MomentoConx : TDateTime;               // Momento en que se debe realizar la conexi�n
      fecha       : string;
      hora        : string;
      pEnHora     : TNotifyEvent;            // Ejecuta la conexi�n autom�tica con los equipos
      Timer       : TTimer;
      indexConex  : integer;                 // Me indica cual es la conexi�n activa
      Conectado   : boolean;                 // Flag que indica si estoy conectado con alg�n equipo 
      tablaInter  : array [1..6] of real;

      constructor Crear;
      destructor  Destruir;
      procedure   EnTimer(Sender: TObject);
      procedure   IniciarCuentaRegreciva;
      procedure   PararCuentaRegreciva;
      procedure   CalcularMomentoConx;
      procedure   CalcularFecha;
      function    ChequearParam:boolean;
  end;

  TConexTelef = record                       // Registro que almacena las config de la com telef�nica
                  Nombre    : string;
                  Ntelefono : string;
                  NLlamadas : integer;
                  Select    : char;
                end;

  TConexionesTelef = class(Tobject)          // Objeto que administra las comunicaciones telef�nicas
    private
      //
    public
      NombreINI   : string;
      NumConex    : integer;
      AConexiones : array of TConexTelef;

      constructor Crear;
      destructor  Destruir;
      function    GuardarConexiones():boolean;
      function    CargarConexiones():boolean;
      function    AgregarConex(NuevaConex : TConexTelef):boolean;
      function    BorrarConex(index : integer):boolean;
  end;

implementation

////////////////////////////////////////////////////////////////////////////////
//TConexAuto
////////////////////////////////////////////////////////////////////////////////
constructor TConexAuto.Crear;
begin
  intervalo      := 0;
  CritDesconec   := 1; 
  fecha          := FormatDateTime('dd/mm/yy',now+1);
  hora           := FormatDateTime('hh:nn',now);
  pEnHora        := nil;
  indexConex     := 0;
  Conectado      := false;

  // Configuro las variables del timer
  Timer          := TTimer.Create(nil);
  Timer.OnTimer  := EnTimer;
  Timer.Interval := 1000;         // Un seg;
  Timer.Enabled  := false;

  // Creo la tabla de intervalos
  tablaInter[1] := 1/(24*30); tablaInter[2] := 1;  tablaInter[3] := 3;
  tablaInter[4] := 7;   tablaInter[5] := 10; tablaInter[6] := 15;
end;

////////////////////////////////////////////////////////////////////////////////
destructor  TConexAuto.Destruir;
begin
  Timer.Destroy;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TConexAuto.EnTimer(Sender: TObject);
begin
  Timer.Interval := 1000;         // Un seg;
  Timer.Enabled  := true;

  // Realizo la conexi�n en el momento prefijado
  if (not (Conectado)) and (MomentoConx < now) and (intervalo > 0) then begin
    // Paro el timer
    Timer.Enabled := false;

    CalcularFecha;                      // Calculo la nueva fecha de conexi�n
    CalcularMomentoConx;                // Calculo el momento (datetime) en que se debe realizar la nueva conexi�n
    pEnHora(nil);                       // Ejecuto el codigo cuando se cumple el tiempo

    // Espero un tiempo mayor ya que no es necesario que siga chequeando
    Timer.Interval := 2000;             // Dos seg;
    Timer.Enabled  := true;
    exit;
  end;

  // Con esto realizo el ciclo para conectarme con todos
  if (indexConex > 0) and (intervalo > 0) then begin
    // Paro el timer
    Timer.Enabled := false;
    // Ejecuto el procedimiento de conexi�n
    pEnHora(nil);
    // Espero un tiempo mayor ya que no es necesario que siga chequeando
    Timer.Interval := 2000;             // Dos seg;
    Timer.Enabled  := true;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TConexAuto.IniciarCuentaRegreciva;
begin
  Timer.Interval := 1000;         // Un seg;
  Timer.Enabled  := true;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TConexAuto.PararCuentaRegreciva;
begin
  Timer.Enabled := false;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TConexAuto.CalcularMomentoConx;
begin
  MomentoConx := StrToDateTime(fecha +' '+ hora);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TConexAuto.CalcularFecha;
var
  aux : real;

begin
  // Calculo la nueva fecha y hora
  if (intervalo > 0) then begin
    aux := StrToDateTime(fecha +' '+ hora);

    while (aux < now) do begin
      aux := aux + tablaInter[intervalo];
    end;

    fecha := FormatDateTime('dd/mm/yy',aux);
    hora  := FormatDateTime('hh:nn',aux);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TConexAuto.ChequearParam:boolean;
begin
  result := true;

  // Me aseguro que si el intervalo est� mal no haga nada
  if not (intervalo<=6) then  intervalo := 0;

  // Me aseguro que si el criterio est� mal lo pongo por defecto
  if not (CritDesconec<=1) then  CritDesconec := 1;

  try
    // Me aseguro que la fecha sea correcta
    StrToDateTime(fecha +' '+ hora);
    
  except
    // Me aseguro que no este habilitada la conexi�n autom�tica
    intervalo := 0;

    // Le asigno una nueva fecha
    fecha  := FormatDateTime('dd/mm/yy',now+1);
    hora   := FormatDateTime('hh:nn',now);
    result := false;

    // Cartel de Informac�on
    MessageBox(0,'Hay un error en la fecha o en la hora.', PChar('Mercury'), MB_OK	or MB_ICONERROR );
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//TConexionesTelef
////////////////////////////////////////////////////////////////////////////////
constructor TConexionesTelef.Crear;
begin
  NombreINI := '';
  NumConex  := 0;
  SetLength(AConexiones,0);
end;

////////////////////////////////////////////////////////////////////////////////
destructor TConexionesTelef.Destruir;
begin
  // Me aseguro que no quede la memoria ocupada
  NombreINI := '';
  NumConex  := 0;
  SetLength(AConexiones,0);
end;

////////////////////////////////////////////////////////////////////////////////
function TConexionesTelef.GuardarConexiones():boolean;
var
  ArchivoINI   : TIniFile;
  i            : integer;

begin
  // Me aseguro que existan coenxiones para ser guardadas
  if not (NumConex>0) then begin
    result := true;
    exit;
  end;

  // Borro el viejo archivo para asegurarme que no quede basura
  if FileExists(NombreINI) then begin
    if not DeleteFile(NombreINI) then begin
      result := true;
      exit;
    end;
  end;

  ArchivoINI   := TIniFile.Create(NombreINI);

  // Guardo los datos en el Archivo INI
  try
    for i:=0 to (NumConex-1) do begin
      ArchivoINI.WriteString(AConexiones[i].Nombre,'Nombre'   , AConexiones[i].Nombre);
      ArchivoINI.WriteString(AConexiones[i].Nombre,'Ntelefono', AConexiones[i].Ntelefono);
      ArchivoINI.WriteString(AConexiones[i].Nombre,'Select'   , AConexiones[i].Select);
      ArchivoINI.WriteString(AConexiones[i].Nombre,'NLlamadas', intToStr(AConexiones[i].NLlamadas));

      // Pongo un separador de las distintas secciones
      ArchivoINI.WriteString(AConexiones[i].Nombre,'------','------');
    end;
  except
    ArchivoINI.Free;
    result := false;
    exit;
  end;

  ArchivoINI.Free;
  //SeccionesINI.Free;
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TConexionesTelef.CargarConexiones():boolean;
var
  ArchivoINI   : TIniFile;
  SeccionesINI : TStrings;
  i            : integer;

begin
  SeccionesINI := TStringList.Create;
  ArchivoINI   := TIniFile.Create(NombreINI);

  if not FileExists(ArchivoINI.FileName) then begin
    ArchivoINI.Free;
    SeccionesINI.Free;
    result := false;
    exit;
  end;

  SeccionesINI.Clear;
  ArchivoINI.ReadSections(SeccionesINI);

  // Cargo los datos desde el Archivo INI
  try
    SetLength(AConexiones, SeccionesINI.Count);
    NumConex := SeccionesINI.Count;
    for i:=0 to SeccionesINI.Count-1 do begin
      AConexiones[i].Nombre    := SeccionesINI.Strings[i];
      AConexiones[i].Ntelefono := ArchivoINI.ReadString(AConexiones[i].Nombre,'Ntelefono', '00000000');
      AConexiones[i].Select    := ArchivoINI.ReadString(AConexiones[i].Nombre,'Select', 'N')[1];      
      AConexiones[i].NLlamadas := StrToInt(ArchivoINI.ReadString(AConexiones[i].Nombre,'NLlamadas', '0'));
    end;

  except
    SetLength(AConexiones,0); 
    NumConex := 0;
    ArchivoINI.Free;
    result := false;
    exit;
  end;

  ArchivoINI.Free;
  SeccionesINI.Free;
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TConexionesTelef.AgregarConex(NuevaConex : TConexTelef):boolean;
begin
  // Obtengo la cantidad de conexiones existentes
  NumConex := length(AConexiones);

  // Creo el espacio para la nueva conexi�n
  SetLength(AConexiones, NumConex+1);

  // Obtengo la cantidad de conexiones existentes
  NumConex := length(AConexiones);

  // Cargo la info de la nueva conexi�n
  AConexiones[NumConex-1].Nombre    := NuevaConex.Nombre;
  AConexiones[NumConex-1].Ntelefono := NuevaConex.Ntelefono;
  AConexiones[NumConex-1].NLlamadas := NuevaConex.NLlamadas;
  AConexiones[NumConex-1].Select    := NuevaConex.Select;  

  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
function TConexionesTelef.BorrarConex(index : integer):boolean;
var
  i : integer;
begin
  // Muevo todas las conexiones para ocupar el lugar a borrar
  for i:=index to NumConex-2 do begin
    AConexiones[i].Nombre    := AConexiones[i+1].Nombre;
    AConexiones[i].Ntelefono := AConexiones[i+1].Ntelefono;
    AConexiones[i].NLlamadas := AConexiones[i+1].NLlamadas;
    AConexiones[i].Select    := AConexiones[i+1].Select;    
  end;

  // Borro el �ltimo lugar
  SetLength(AConexiones, NumConex-1);

  // Obtengo la cantidad de conexiones existentes
  NumConex := length(AConexiones);

  result := true;
end;

////////////////////////////////////////////////////////////////////////////////
end.
