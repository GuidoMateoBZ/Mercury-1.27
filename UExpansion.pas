unit UExpansion;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin;

type

  { TFExpansion }

  TFExpansion = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    rbCanales24: TRadioButton;
    rbCanales32: TRadioButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure RadioButton1Change(Sender: TObject);
    procedure RadioButton2Change(Sender: TObject);
  private

  public

  end;

var
  FExpansion: TFExpansion;

implementation

uses Uprincipal;

{$R *.lfm}

{ TFExpansion }

procedure TFExpansion.Label1Click(Sender: TObject);
begin

end;

procedure TFExpansion.FormCreate(Sender: TObject);
begin

end;

procedure TFExpansion.Button1Click(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TFExpansion.RadioButton1Change(Sender: TObject);
begin

end;

procedure TFExpansion.RadioButton2Change(Sender: TObject);
begin

end;

end.

