unit UServerSocket;

interface
uses
  Windows, Registry, Classes, SysUtils, Dialogs, StdCtrls, SyncObjs, Math,
  UUtiles, Sockets, UEquipoInternet;

type
  TServer = class(Tobject)
    private
      //
    public
      SrvSocket   : TServerSocket;
      pTStrings   : TpTstrings;
      FormatFecha : string;

      constructor Crear(port: integer; pTString: TpTstrings);
      destructor  Destruir;
      procedure   ServerSocket_OnListen(Sender: TObject; Socket: TCustomWinSocket);
      procedure   ServerSocket_OnAccept(Sender: TObject; Socket: TCustomWinSocket);
      procedure   ServerSocket_ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
      procedure   ServerSocket_OnClientError(Sender: TObject; Socket: TCustomWinSocket;
                                             ErrorEvent: TErrorEvent; var ErrorCode: Integer);
      procedure   ServerSocket_OnGetThread(Sender: TObject; ClientSocket: TServerClientWinSocket;
                                           var SocketThread: TServerClientThread);
  end;

implementation

////////////////////////////////////////////////////////////////////////////////
//TServerSocket
////////////////////////////////////////////////////////////////////////////////
constructor TServer.Crear(port: integer; pTString: TpTStrings);
begin
  // Configuro las variables generales del Server
  FormatFecha := 'dd/mm/yy hh:nn:ss ';
  pTStrings   := pTString;

  // Creo los sockets
  SrvSocket := TServerSocket.Create(nil);

  // Configuro el socket servidor
  //Socket.OnClientRead       := ServerSocket_ClientRead;

  // Configuro el socket servidor
  SrvSocket.OnListen           := ServerSocket_OnListen;
  SrvSocket.OnAccept           := ServerSocket_OnAccept;
  SrvSocket.OnClientDisconnect := ServerSocket_ClientDisconnect;
  SrvSocket.OnClientError      := ServerSocket_OnClientError;
  SrvSocket.OnGetThread        := ServerSocket_OnGetThread;
  SrvSocket.Port               := port;
  SrvSocket.ServerType         := stTHREADBLOCKING; //stNonBlocking;//stTHREADBLOCKING;
  SrvSocket.Active             := false;
end;

destructor TServer.Destruir;
begin
  SrvSocket.Destroy;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TServer.ServerSocket_OnListen(Sender: TObject; Socket: TCustomWinSocket);
var
  strHora : string;

begin
  if (pTStrings = nil) then exit;

  strHora := FormatDateTime(FormatFecha, now);
  pTStrings^.Add(strHora + ' -> El servidor est� escuchando en el puerto ' + IntToStr(SrvSocket.Port) +'...');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TServer.ServerSocket_OnAccept(Sender: TObject; Socket: TCustomWinSocket);
var
  strHora : string;

begin
  if (pTStrings = nil) then exit;

  strHora := FormatDateTime(FormatFecha, now);
  pTStrings^.Add(strHora + ' -> Cliente conectado.');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TServer.ServerSocket_ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
var
  strHora : string;

begin
  if (pTStrings = nil) then exit;

  strHora := FormatDateTime(FormatFecha, now);
  pTStrings^.Add(strHora + ' -> Cliente desconectado.');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TServer.ServerSocket_OnClientError(Sender: TObject; Socket: TCustomWinSocket;
          ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  if (pTStrings = nil) then exit;

  case ErrorEvent of
    eeGeneral    : pTStrings^.Add('Ocurrio un error general en la conexi�n');
    eeSend       : pTStrings^.Add('Ocurrio un error al escribir en la conexi�n');
    eeReceive    : pTStrings^.Add('Ocurrio un error al leer de la conexi�n');
    eeConnect    : pTStrings^.Add('Un pedido de conexi�n fue aceptado pero no completado');
    eeDisconnect : pTStrings^.Add('Un error ocurrio cuando se trataba de cerrar la conexi�n');
    eeAccept     : pTStrings^.Add('Un error ocurrio cuando se trataba de aceptar un pedido de conexi�n');
  else
    pTStrings^.Add('Ocurrio un error general en la conexi�n');
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TServer.ServerSocket_OnGetThread(Sender: TObject; ClientSocket: TServerClientWinSocket;
          var SocketThread: TServerClientThread);
begin
  // 50000
  SocketThread := TServEquipoThread.Create( false, ClientSocket, 50000, 10, pTStrings, Mercury.DirDatosInternet);
end;

////////////////////////////////////////////////////////////////////////////////
end.
