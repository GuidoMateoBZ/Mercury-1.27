unit UAnemometro;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, RoundButton;

type
  TFAnemometro = class(TForm)
    ImgAnemometro: TImage;
    ImgN: TImage;
    ImgNNE: TImage;
    ImgNE: TImage;
    ImgENE: TImage;
    ImgE: TImage;
    ImgESE: TImage;
    ImgSE: TImage;
    ImgSSE: TImage;
    ImgS: TImage;
    ImgSSW: TImage;
    ImgSW: TImage;
    ImgWSW: TImage;
    ImgW: TImage;
    ImgWNW: TImage;
    ImgNW: TImage;
    ImgNNW: TImage;
    LDireccion: TLabel;
    LVelocidad: TLabel;
    Label2: TLabel;
    RBApagado: TRoundButton;
    ScrollBar1: TScrollBar;
    procedure RBApagadoClick(Sender: TObject);
    procedure ImgAnemometroMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure ImgAnemometroMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImgAnemometroMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    
  private
    { Private declarations }
  public
    procedure ActualizarDatos(Grados:integer; Velocidad:real);
  end;

var
  FAnemometro     : TFAnemometro;
  mbLeftApretado  : boolean;
  Xini, Yini      : integer;

implementation

{$R *.dfm}
////////////////////////////////////////////////////////////////////////////////
procedure TFAnemometro.FormCreate(Sender: TObject);
begin
  mbLeftApretado := false;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFAnemometro.ActualizarDatos(Grados:integer; Velocidad:real);
begin
  //  Oculto las Flechas
  ImgN.Visible   := false;
  ImgNNE.Visible := false;
  ImgNE.Visible  := false;
  ImgNW.Visible  := false;
  ImgNNW.Visible := false;
  ImgENE.Visible := false;
  ImgE.Visible   := false;
  ImgESE.Visible := false;
  ImgSE.Visible  := false;
  ImgSSW.Visible := false;
  ImgSW.Visible  := false;
  ImgS.Visible   := false;
  ImgSSE.Visible := false;
  ImgWSW.Visible := false;
  ImgW.Visible   := false;
  ImgWNW.Visible := false;

  // Muestro la Flecha Correspondiente
  case grados of
    0..11     : begin
                  ImgN.Visible        := True;
                  LDireccion.Caption  := 'N';
                end;
    12..33    : begin
                  ImgNNE.Visible      := True;
                  LDireccion.Caption  := 'NNE';
                end;
    34..56    : begin
                  ImgNE.Visible       := True;
                  LDireccion.Caption  := 'NE';
                end;
    57..78    : begin
                  ImgENE.Visible      := True;
                  LDireccion.Caption  := 'ENE';
                end;
    79..101   : begin
                  ImgE.Visible        := True;
                  LDireccion.Caption  := 'E';
                end;
    102..123  : begin
                  ImgESE.Visible      := True;
                  LDireccion.Caption  := 'ESE';
                end;
    124..146  : begin
                  ImgSE.Visible       := True;
                  LDireccion.Caption  := 'SE';
                end;
    147..168  : begin
                  ImgSSE.Visible      := True;
                  LDireccion.Caption  := 'SSE';
                end;
    169..191  : begin
                  ImgS.Visible        := True;
                  LDireccion.Caption  := 'S';
                end;
    192..213  : begin
                  ImgSSW.Visible      := True;
                  LDireccion.Caption  := 'SSW';
                end;

    214..236  : begin
                  ImgSW.Visible       := True;
                  LDireccion.Caption  := 'SW';
                end;
    237..258  : begin
                  ImgWSW.Visible      := True;
                  LDireccion.Caption  := 'WSW';
                end;
    259..281  : begin
                  ImgW.Visible        := True;
                  LDireccion.Caption  := 'W';
                end;
    282..303  : begin
                  ImgWNW.Visible      := True;
                  LDireccion.Caption  := 'WNW';
                end;
    304..326  : begin
                  ImgNW.Visible       := True;
                  LDireccion.Caption  := 'NW';
                end;
    327..348  : begin
                  ImgNNW.Visible      := True;
                  LDireccion.Caption  := 'NNW';
                end;
    349..360  : begin
                  ImgN.Visible        := True;
                  LDireccion.Caption  := 'N';
                end;
  end;
  LVelocidad.Caption := FormatFloat('0.0',Velocidad);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFAnemometro.RBApagadoClick(Sender: TObject);
begin
  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFAnemometro.ImgAnemometroMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if not mbLeftApretado then exit;
  
  Top  := top  + (Y-Yini);
  Left := Left + (X-Xini);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFAnemometro.ImgAnemometroMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then mbLeftApretado := true;
  
  Xini := X;
  Yini := Y;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFAnemometro.ImgAnemometroMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  mbLeftApretado := false; 
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFAnemometro.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
end.

