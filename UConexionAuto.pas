unit UConexionAuto;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, CheckLst, Buttons, MaskEdit, UUtiles;

type
  TFConexionAuto = class(TForm)
    Image1: TImage;
    Panel1: TPanel;
    Panel2: TPanel;
    Bevel1: TBevel;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    clbListaConexiones: TCheckListBox;
    sbCerrar: TSpeedButton;
    sbAceptar: TSpeedButton;
    GroupBox2: TGroupBox;
    cbIntervalo: TComboBox;
    Label1: TLabel;
    Bevel2: TBevel;
    Label2: TLabel;
    meFecha: TMaskEdit;
    Label3: TLabel;
    meHora: TMaskEdit;
    Label4: TLabel;
    cbDeconectar: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sbAceptarClick(Sender: TObject);
    procedure sbCerrarClick(Sender: TObject);
    procedure cbIntervaloChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    pMercury : ^TMercury;
  end;

var
  FConexionAuto   : TFConexionAuto;
  porPrimeraVez   : boolean;
  oldIntervalo    : integer;
  oldCritDesconec : integer;
  oldFecha        : string;
  oldHora         : string;

implementation

uses UConexiones;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionAuto.FormCreate(Sender: TObject);
begin
  porPrimeraVez := true;

end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionAuto.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionAuto.sbAceptarClick(Sender: TObject);
var
  i :integer;

begin
  // Asigno el nuevo intervalo de conexi�n
  pMercury^.ConexAuto.intervalo := cbIntervalo.ItemIndex;

  // Asigno el nuevo criterio de desconecci�n
  pMercury^.ConexAuto.CritDesconec := cbDeconectar.ItemIndex;

  // Asigno la nueva fecha de conexi�n
  pMercury^.ConexAuto.fecha := meFecha.Text;

  // Asigno la nueva hora de conexi�n
  pMercury^.ConexAuto.hora := meHora.Text;

  // Chequeo los par�metros de la conexi�n autom�tica
  if  not pMercury^.ConexAuto.ChequearParam then exit;

  // Me aseguro que la fecha este el en futuro
  if (StrToDateTime(pMercury^.ConexAuto.fecha +' '+ pMercury^.ConexAuto.hora) < now) then begin
    MessageBox(handle,'Error en la fecha, el momento elegido ya pas�.', PChar('Mercury'), MB_OK	or MB_ICONERROR );
    exit;
  end;

  // Asigno la nueva configuraci�n de las conexiones
  for i:=0 to pMercury^.ConexTelefon.NumConex-1 do begin
    if clbListaConexiones.Checked[i] then pMercury^.ConexTelefon.AConexiones[i].Select := 'S'
    else pMercury^.ConexTelefon.AConexiones[i].Select := 'N';
  end;

  // habilito la timer para la conexi�n
  pMercury^.ConexAuto.CalcularFecha;
  pMercury^.ConexAuto.CalcularMomentoConx;

  // Inicio la cuenta regreciva de ser necesario
  if (pMercury^.TipoDeComm = 1) and (pMercury^.ConexAuto.intervalo>0) then Mercury.ConexAuto.IniciarCuentaRegreciva
  else Mercury.ConexAuto.PararCuentaRegreciva;  

  pMercury^.GuardarConfig;
  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionAuto.sbCerrarClick(Sender: TObject);
begin
  // Restauro los valores originales
  pMercury^.ConexAuto.intervalo    := oldIntervalo;
  pMercury^.ConexAuto.CritDesconec := oldCritDesconec;
  pMercury^.ConexAuto.fecha        := oldFecha;
  pMercury^.ConexAuto.hora         := oldHora;

  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionAuto.cbIntervaloChange(Sender: TObject);
begin
  if cbIntervalo.ItemIndex = 0 then begin
    clbListaConexiones.Enabled := false;
    meFecha.Enabled            := false;
    meHora.Enabled             := false;
    cbDeconectar.Enabled       := false;
  end
  else begin
    clbListaConexiones.Enabled := true;
    meFecha.Enabled            := true;
    meHora.Enabled             := true;
    cbDeconectar.Enabled       := true;    
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionAuto.FormActivate(Sender: TObject);
var
  i : integer;

begin
  if not porPrimeraVez then exit;
  porPrimeraVez := false;

  // Cargo la config de las conexiones
  clbListaConexiones.Clear;
  for i:=0 to pMercury^.ConexTelefon.NumConex-1 do begin
    clbListaConexiones.Items.Add(pMercury^.ConexTelefon.AConexiones[i].Nombre);
    if pMercury^.ConexTelefon.AConexiones[i].Select = 'S' then clbListaConexiones.Checked[i] := true;
  end;

  // Cargo el intervalo de conexi�n
  cbIntervalo.ItemIndex := pMercury^.ConexAuto.intervalo;
  oldIntervalo          := pMercury^.ConexAuto.intervalo;

  // Cargo el Criterio de desconecci�n
  cbDeconectar.ItemIndex := pMercury^.ConexAuto.CritDesconec;
  oldCritDesconec        := pMercury^.ConexAuto.CritDesconec;

  // Cargo la fecha de la conexi�n
  meFecha.Text := pMercury^.ConexAuto.fecha;
  oldFecha     := pMercury^.ConexAuto.fecha;

  // Cargo la hora de la conexi�n
  meHora.Text := pMercury^.ConexAuto.hora;
  oldHora     := pMercury^.ConexAuto.hora;

  // Actualizo el estado de los objetos
  cbIntervaloChange(nil);
end;

////////////////////////////////////////////////////////////////////////////////
end.
