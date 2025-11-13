unit UConexionesRemotas;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, ComCtrls, ImgList, UConexiones;

type
  TFConexionesRemotas = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    ENombreConex: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    ENumConex: TEdit;
    Bevel2: TBevel;
    sbCerrar: TSpeedButton;
    Bevel1: TBevel;
    LBConexiones: TListBox;
    sbNuevaCon: TSpeedButton;
    sbBorrarCon: TSpeedButton;
    Panel3: TPanel;
    Bevel3: TBevel;
    Image1: TImage;
    sbAplicar: TSpeedButton;
    Label3: TLabel;
    LNumLlamadas: TLabel;
    Label4: TLabel;
    LSelect: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sbAplicarClick(Sender: TObject);
    procedure sbCerrarClick(Sender: TObject);
    procedure sbNuevaConClick(Sender: TObject);
    procedure sbBorrarConClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ActualizarInfoConex;
    procedure LBConexionesClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    pConexTelefon : ^TConexionesTelef;
  end;

var
  FConexionesRemotas : TFConexionesRemotas;
  porPrimeraVez      : boolean;
  ConexionAux        : TConexTelef;

implementation

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.FormCreate(Sender: TObject);
begin
  // Inicializo las variable y objetos básicos
  porPrimeraVez        := true;
  ENombreConex.Text    := '';
  ENumConex.Text       := '';
  LNumLlamadas.Caption := '';
  LSelect.Caption      := '';      
  LBConexiones.Items.Clear;

  ConexionAux.Nombre    := 'Sin Nombre';
  ConexionAux.Ntelefono := '0000000';
  ConexionAux.NLlamadas := 0;
  ConexionAux.Select    := 'N';
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.FormActivate(Sender: TObject);
var
  i : integer;

begin
  if not porPrimeraVez then exit;
  porPrimeraVez := false;

  // Cargo las conexiones existentes
  for i:=0 to pConexTelefon^.NumConex-1 do begin
    LBConexiones.Items.Add(pConexTelefon^.AConexiones[i].Nombre);
  end;  

  if LBConexiones.Items.Count > 0 then LBConexiones.ItemIndex :=0;
  ActualizarInfoConex;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.sbAplicarClick(Sender: TObject);
begin
  pConexTelefon^.AConexiones[LBConexiones.ItemIndex].Nombre    := ENombreConex.Text;
  pConexTelefon^.AConexiones[LBConexiones.ItemIndex].Ntelefono := ENumConex.Text;
  LBConexiones.Items.Strings[LBConexiones.ItemIndex]           := ENombreConex.Text;

  if pConexTelefon^.GuardarConexiones then
    MessageBox(Handle,'Los cambios han sido guardados.', PChar(Caption), MB_OK	or MB_ICONINFORMATION )
  else
    MessageBox(Handle,'Ocurrio un error al guardar las conexiones.', PChar(Caption), MB_OK	or MB_ICONERROR );
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.sbCerrarClick(Sender: TObject);
begin
  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.sbNuevaConClick(Sender: TObject);
var
  msg : integer;

begin
  msg := MessageBox(Handle,'¿Seguro que desea agregar una nueva conexión telefónica?',
                    PChar(Caption), MB_YESNO or MB_ICONQUESTION );
  if (msg = 7) then exit;     // Presiono el Boton "NO", No hago nada

  // Agrego el nombre de la Nueva conexión a lista 
  LBConexiones.Items.Add(ConexionAux.Nombre);
  LBConexiones.ItemIndex := LBConexiones.Items.Count-1;

  // Agrego la nueva conexión
  pConexTelefon^.AgregarConex(ConexionAux);

  // Actualizo la vista de la info de la conexión
  ActualizarInfoConex;

  // Guardo la nueva conexión
  if not pConexTelefon^.GuardarConexiones then
    MessageBox(Handle,'Ocurrio un error al guardar las conexiones.', PChar(Caption), MB_OK	or MB_ICONERROR );
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.sbBorrarConClick(Sender: TObject);
var
  Nitem, msg : integer;

begin
  msg := MessageBox(Handle,'¿Seguro que desea borrar la conexión telefónica?',
                    PChar(Caption), MB_YESNO or MB_ICONQUESTION );
  if (msg = 7) then exit;     // Presiono el Boton "NO", No hago nada

  Nitem := LBConexiones.ItemIndex;
  if LBConexiones.Items.Count > 0 then LBConexiones.Items.Delete(LBConexiones.ItemIndex);

  // Me aseguro que el foco quede en el item anterior
  if Nitem > 0 then LBConexiones.ItemIndex := Nitem-1
  else LBConexiones.ItemIndex := 0;

  // Borro la conexión
  pConexTelefon^.BorrarConex(Nitem);

  // Guardo las  conexiones
  if not pConexTelefon^.GuardarConexiones then
    MessageBox(Handle,'Ocurrio un error al guardar las conexiones.', PChar(Caption), MB_OK	or MB_ICONERROR );
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.ActualizarInfoConex;
begin
  // Limpio la info por las dudas
  ENombreConex.Text    := '';
  ENumConex.Text       := '';
  LNumLlamadas.Caption := '';
  LSelect.Caption      := '';
  if not (pConexTelefon^.NumConex>0) then exit;

  // Cargo la nueva info
  ENombreConex.Text    := pConexTelefon^.AConexiones[LBConexiones.ItemIndex].Nombre;
  ENumConex.Text       := pConexTelefon^.AConexiones[LBConexiones.ItemIndex].Ntelefono;
  LNumLlamadas.Caption := intToStr(pConexTelefon^.AConexiones[LBConexiones.ItemIndex].NLlamadas);
  if pConexTelefon^.AConexiones[LBConexiones.ItemIndex].Select = 'S' then LSelect.Caption := 'SI'
  else LSelect.Caption := 'NO';
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFConexionesRemotas.LBConexionesClick(Sender: TObject);
begin
  ActualizarInfoConex;
end;

////////////////////////////////////////////////////////////////////////////////
end.
