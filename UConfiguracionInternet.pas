unit UConfiguracionInternet;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UUtiles, Buttons, ExtCtrls, StdCtrls, UEquipo, MaskEdit;

type
  TFConfiguracionInternet = class(TForm)
    Image1: TImage;
    Panel1: TPanel;
    sbCerrar: TSpeedButton;
    sbConfigEquipo: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    eGateway: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    eUser: TEdit;
    Label3: TLabel;
    ePass: TEdit;
    Label4: TLabel;
    eDirServer: TEdit;
    Port: TLabel;
    mePort: TMaskEdit;
    GroupBox3: TGroupBox;
    Label6: TLabel;
    cbIntervaloConect: TComboBox;
    procedure sbCerrarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sbConfigEquipoClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    pEquipo  : ^TEquipo;
  end;

var
  FConfiguracionInternet : TFConfiguracionInternet;
  PorPrimeraVez          : boolean;

implementation

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TFConfiguracionInternet.FormCreate(Sender: TObject);
begin
  PorPrimeraVez := true;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConfiguracionInternet.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConfiguracionInternet.sbCerrarClick(Sender: TObject);
begin
  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConfiguracionInternet.sbConfigEquipoClick(Sender: TObject);
begin
  if not pEquipo^.ThreadComm.ONLine then begin
    // Cartel de Informac�on
    MessageBox(Handle,'El equipo no se encuentra conectado.', PChar(Caption), MB_OK	or MB_ICONERROR );
    exit;
  end;

  // Chequeo la integridad de los valores antes de aceptarlos
  // Chequeo el puerto
  if not ((StrToInt(mePort.Text)>20) and (StrToInt(mePort.Text)<65536)) then begin
    // Cartel de Informac�on
    MessageBox(Handle,'El puerto debe ser mayor a 20 y menor a 65536' , PChar(Caption), MB_OK	or MB_ICONERROR );
    exit;
  end;

  // Chequeo el periodo de Conexi�n
  if (pEquipo^.ThreadComm.CalcPeriodoConect(cbIntervaloConect.ItemIndex)=65535) then begin
    // Cartel de Informac�on
    MessageBox(Handle,'No se puede conectar con ese intervalo debido al periodo de muestreo actual.', PChar(Caption), MB_OK	or MB_ICONERROR );
    exit;
  end;

  // Cargo los nuevos par�metros al thread para que configure el equipo
  pEquipo^.ThreadComm.gateway      := eGateway.Text;
  pEquipo^.ThreadComm.user         := eUser.Text;
  pEquipo^.ThreadComm.pass         := ePass.Text;
  pEquipo^.ThreadComm.server       := eDirServer.Text;
  pEquipo^.ThreadComm.port         := mePort.Text;
  pEquipo^.ThreadComm.IndexTConect := cbIntervaloConect.ItemIndex;

  // Cargo los nuevos valores para guardarlos 
  Mercury.Gateway      := eGateway.Text;
  Mercury.user         := eUser.Text;
  Mercury.pass         := ePass.Text;
  Mercury.DirServer    := eDirServer.Text;
  Mercury.Puerto       := StrToInt(mePort.Text);
  Mercury.IndexTConect := cbIntervaloConect.ItemIndex;

  // Activo el flag para que transmita la configuraci�n
  pEquipo^.ThreadComm.ConfigInternetEquipo := true;
  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConfiguracionInternet.FormActivate(Sender: TObject);
begin
  if not PorPrimeraVez then exit;
  PorPrimeraVez := false;

  //  Leo la config de internet del equipo
  eGateway.Text               := Mercury.Gateway;
  eUser.Text                  := Mercury.User;
  ePass.Text                  := Mercury.Pass;
  eDirServer.Text             := Mercury.DirServer;
  mePort.Text                 := intToStr(Mercury.Puerto);
  cbIntervaloConect.ItemIndex := Mercury.IndexTConect
end;

////////////////////////////////////////////////////////////////////////////////
end.
