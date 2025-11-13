unit UServerSocket;

interface
uses
  Windows, Registry, Classes, SysUtils, Dialogs, StdCtrls, SyncObjs, Math,
  UUtiles, ScktComp;

type
  TServerSocket = class(Tobject)
    private
      //
    public
      constructor Crear(NCanales:byte; COMM:string; TipoCom: byte);
      destructor  Destruir;
  end;
  
implementation

end.
