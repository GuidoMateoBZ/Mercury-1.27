unit UPresentacion;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TFPresentacion = class(TForm)
    Image1: TImage;
    LMensaje: TLabel;
    Timer1: TTimer;
    Label1: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FPresentacion: TFPresentacion;

implementation

{$R *.lfm}

////////////////////////////////////////////////////////////////////////////////
procedure TFPresentacion.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFPresentacion.Timer1Timer(Sender: TObject);
begin
  close;
end;

////////////////////////////////////////////////////////////////////////////////
end.
