unit UColor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls;

type
  TFColor = class(TForm)
    ColorDialog1: TColorDialog;
    CBSeries: TComboBox;
    Bevel1: TBevel;
    BClose: TSpeedButton;
    BSColor: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure BCloseClick(Sender: TObject);
    procedure Principal(var Ejecuto :boolean;var Color:Tcolor;var index :integer);
    procedure BSColorClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FColor: TFColor;
  pColor : ^Tcolor;
  Pejecuto : ^Boolean;
  pIndex : ^integer;

implementation

{$R *.DFM}
////////////////////////////////////////////////////////////////////////////////
procedure TFColor.FormCreate(Sender: TObject);
begin
//  ColorDialog1.
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFColor.BCloseClick(Sender: TObject);
begin
  Close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFColor.Principal(var Ejecuto :boolean;var Color:Tcolor;var index :integer);
begin
   Ejecuto := False;
   Pejecuto := @Ejecuto;
   pColor := @Color;
   Pindex := @index;
   ShowModal;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFColor.BSColorClick(Sender: TObject);
begin
   if ColorDialog1.Execute then
   begin
      pColor^ := ColorDialog1.color;
      pEjecuto^ := True;
      Pindex^ := CBSeries.itemindex;
   end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFColor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
end.
