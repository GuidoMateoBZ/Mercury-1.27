unit UCalculoParam;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, ComCtrls, StdCtrls, UEquipo, UUtiles;

type
  TFCalculoParam = class(TForm)
    Panel1: TPanel;
    sbAceptar: TSpeedButton;
    sbCerrar: TSpeedButton;
    Bevel2: TBevel;
    Image1: TImage;
    GroupBox1: TGroupBox;
    LTitulo: TLabel;
    Label2: TLabel;
    LParam00: TLabel;
    LParam01: TLabel;
    LParam02: TLabel;
    cbHabilitaParam: TCheckBox;
    mComentario: TMemo;
    cbParam01: TComboBox;
    cbParam02: TComboBox;
    cbParam00: TComboBox;
    LParam03: TLabel;
    cbParam03: TComboBox;
    LParam04: TLabel;
    cbParam04: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sbAceptarClick(Sender: TObject);
    procedure sbCerrarClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);

    // Salinidad
    procedure CargarParam;
    procedure cbHabilitaParamClick(Sender: TObject);
    procedure AceptarParametro;

    // Densidad
    
    // VelocidadSonido

    // Sensación Térmica

  private
    { Private declarations }
  public
    { Public declarations }
    Nparametro : byte;
    pEquipo    : ^TEquipo;
  end;

var
  FCalculoParam: TFCalculoParam;
  ListaCanales : Tstrings;
  ACanales     : array of integer;
  AComboBox    : array [0..4] of ^TComboBox;
  ALabels      : array [0..4] of ^TLabel;
  PrimeraVez   : boolean;

implementation

uses UFormulas;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.FormCreate(Sender: TObject);
begin
  PrimeraVez   := true;
  ListaCanales := TStringList.Create;
  ListaCanales.Clear;

  pEquipo := nil;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  ListaCanales.Free;
  SetLength(ACanales,0);
  Action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.sbAceptarClick(Sender: TObject);
begin
  AceptarParametro;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.sbCerrarClick(Sender: TObject);
begin
  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.FormActivate(Sender: TObject);
var
  i            : byte;

begin
  if not PrimeraVez then exit; 

  // Creo una lista de los canales disponibles
  SetLength(ACanales,1);
  ACanales[0] := -1;
  ListaCanales.Add('No seleccionado');
  for i:=0 to pEquipo^.NumCanales-1  do begin
    if (pEquipo^.Canales[i].Config > 0) then begin
      setLength(ACanales,length(ACanales)+1);
      ListaCanales.Add('Canal '+IntToStr(i));
      ACanales[length(ACanales)-1] := i;
    end;
  end;

  // Creo el Arreglo de punteros a los Cbox
  AComboBox[0] := @cbParam00;   AComboBox[1] := @cbParam01;
  AComboBox[2] := @cbParam02;   AComboBox[3] := @cbParam03;
  AComboBox[4] := @cbParam04;

  // Creo el arreglo de punteros a los Labels
  ALabels[0] := @LParam00;  ALabels[1] := @LParam01;  ALabels[2] := @LParam02;
  ALabels[3] := @LParam03;  ALabels[4] := @LParam04;

  // Cargo la info del parametro, Salinidad, Densidad....
  CargarParam;

  // Me aseguro que solo entre una sola vez
  PrimeraVez := false;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.CargarParam;
var
  i : byte;

begin
  // Habilito el Tilde si esta seleccionado para calcular
  if pEquipo^.CalcParam.Parametros[Nparametro].Calcular = 1 then begin
    cbHabilitaParam.Checked := true;
    cbHabilitaParamClick(nil);
  end;

  // Asigno la lista de los canales disponible a los ComboBox
  for i:=0 to length(AComboBox)-1 do
    AComboBox[i]^.Items.Assign(ListaCanales);

  // Los pongo en "No Seleccionado"
  for i:=0 to length(AComboBox)-1 do begin
    AComboBox[i]^.ItemIndex := 0;
    AComboBox[i]^.Visible   := false;
    ALabels[i]^.Visible     := false;
  end;

  with pEquipo^.CalcParam.Parametros[Nparametro] do begin
    GroupBox1.Caption := ' Cálculo de ' + Descripcion + ' ';
    LTitulo.Caption   := 'Habilitar el cálculo de ' + Descripcion;
    mComentario.Clear;
    mComentario.Lines.Add(Comentario);

    // Cargo la info de los parámetros al los ComboBox y las etiquetas
    for i:=0 to Nparam-1 do begin
      // Descripicón de los parametros
      ALabels[i]^.Caption := AParam[i].descrip;
      ALabels[i]^.Visible := true;  

      // Canales de los parámetros
      if AParam[i].canal >= 0 then AComboBox[i]^.ItemIndex := AParam[i].canal+1;
      AComboBox[i]^.Visible := true;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.cbHabilitaParamClick(Sender: TObject);
var
  i : byte;

begin
  if cbHabilitaParam.Checked then begin
    // Habilito los comboBox
    for i:=0 to pEquipo^.CalcParam.Parametros[Nparametro].Nparam-1 do
      AComboBox[i]^.Enabled := true;
  end
  else begin
    for i:=0 to length(AComboBox)-1 do begin
      // Desabilito los comboBox
      AComboBox[i]^.Enabled := false;
      // Los pongo en "No Seleccionado"
      AComboBox[i]^.ItemIndex := 0;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFCalculoParam.AceptarParametro;
var
    i : byte;
    
begin
  with pEquipo^.CalcParam.Parametros[Nparametro] do begin
    if cbHabilitaParam.Checked then begin
      // Me aseguro que esten seleccionados todos los canales necesarios
      for i :=0 to NparamNecesa-1 do begin
        if (AComboBox[i]^.ItemIndex = 0) then begin
          MessageDlg('¡Faltan seleccionar canales!', mtError,[mbOk], 0);
          exit;
        end;
      end;

      // Si están todos los canales seleccionados
      Calcular := 1;
      for i :=0 to Nparam-1 do begin
        AParam[i].canal := ACanales[AComboBox[i]^.ItemIndex];
        AParam[i].select := 1;
      end;
    end
    else begin
      Calcular := 0;
      for i :=0 to Nparam-1 do begin
        AParam[i].canal := -1;
        AParam[i].select := 0;
      end;
    end;
  end;

  pEquipo.GuardarEquipo(Mercury.NombreINIEquipos);
  close;
end;

////////////////////////////////////////////////////////////////////////////////
end.
