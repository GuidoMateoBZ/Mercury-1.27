unit UOpciones3D;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, ExtCtrls, StdCtrls, DBChart;

type
  TFormOpciones3D = class(TForm)
    Bevel1: TBevel;
    sbCerrar: TSpeedButton;
    GroupBox1: TGroupBox;
    sbrZoom: TScrollBar;
    sbrRotacion: TScrollBar;
    sbrElevacion: TScrollBar;
    sbrHorzOffset: TScrollBar;
    sbrVertOffset: TScrollBar;
    sbrPerspectiva: TScrollBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    LZoom: TLabel;
    LRotacion: TLabel;
    LElevacion: TLabel;
    LHorizOffset: TLabel;
    LVertOffset: TLabel;
    LPerspectiva: TLabel;
    cb3D: TCheckBox;
    Label7: TLabel;
    cbOrtogonal: TCheckBox;
    Label8: TLabel;
    cbZoomTexto: TCheckBox;
    Label9: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sbCerrarClick(Sender: TObject);
    procedure sbrZoomChange(Sender: TObject);
    procedure sbrRotacionChange(Sender: TObject);
    procedure sbrElevacionChange(Sender: TObject);
    procedure sbrHorzOffsetChange(Sender: TObject);
    procedure sbrVertOffsetChange(Sender: TObject);
    procedure sbrPerspectivaChange(Sender: TObject);
    procedure cb3DClick(Sender: TObject);
    procedure cbOrtogonalClick(Sender: TObject);
    procedure cbZoomTextoClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    pDBGrafico : ^TDBChart;
  end;

var
  FormOpciones3D: TFormOpciones3D;

implementation

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.FormCreate(Sender: TObject);
begin
//
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.sbCerrarClick(Sender: TObject);
begin
  close;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.sbrZoomChange(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.Zoom := sbrZoom.Position;
  LZoom.Caption                  := IntToStr(sbrZoom.Position);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.sbrRotacionChange(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.Rotation := sbrRotacion.Position;
  LRotacion.Caption                  := IntToStr(sbrRotacion.Position);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.sbrElevacionChange(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.Elevation := sbrElevacion.Position;
  LElevacion.Caption                  := IntToStr(sbrElevacion.Position);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.sbrHorzOffsetChange(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.HorizOffset := sbrHorzOffset.Position;
  LHorizOffset.Caption                  := IntToStr(sbrHorzOffset.Position);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.sbrVertOffsetChange(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.VertOffset := sbrVertOffset.Position;
  LVertOffset.Caption                  := IntToStr(sbrVertOffset.Position);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.sbrPerspectivaChange(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.Perspective := sbrPerspectiva.Position;
  LPerspectiva.Caption                  := IntToStr(sbrPerspectiva.Position);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.cb3DClick(Sender: TObject);
begin
  pDBGrafico^.View3D := cb3D.Checked;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.cbOrtogonalClick(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.Orthogonal := cbOrtogonal.Checked;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.cbZoomTextoClick(Sender: TObject);
begin
  pDBGrafico^.View3DOptions.ZoomText := cbZoomTexto.Checked;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFormOpciones3D.FormActivate(Sender: TObject);
begin
  cb3D.Checked            := pDBGrafico^.View3D;
  cbZoomTexto.Checked     := pDBGrafico^.View3DOptions.ZoomText;
  cbOrtogonal.Checked     := pDBGrafico^.View3DOptions.Orthogonal;

  sbrPerspectiva.Position := pDBGrafico^.View3DOptions.Perspective;
  sbrVertOffset.Position  := pDBGrafico^.View3DOptions.VertOffset;
  sbrHorzOffset.Position  := pDBGrafico^.View3DOptions.HorizOffset;
  sbrElevacion.Position   := pDBGrafico^.View3DOptions.Elevation;
  sbrRotacion.Position    := pDBGrafico^.View3DOptions.Rotation;
  sbrZoom.Position        := pDBGrafico^.View3DOptions.Zoom;
end;

////////////////////////////////////////////////////////////////////////////////
end.
