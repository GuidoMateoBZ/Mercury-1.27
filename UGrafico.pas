unit UGrafico;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Chart, Series, ComCtrls, ToolWin, UUtiles, Buttons,
  StdCtrls, Menus, DateUtils, ExtDlgs, UColor, shellapi, UOpciones3D,
  UDataModule, TeeProcs, TeEngine, UEquipo, Math;

type
  TFGraficoSensor = class(TForm)
    CoolBar1: TCoolBar;
    ToolBar1: TToolBar;
    tbGuardar: TToolButton;
    tbCopiarCLB: TToolButton;
    tbReporteWeb: TToolButton;
    tbImprimirTabla: TToolButton;
    PopupMenuPaso: TPopupMenu;
    mN1Hora: TMenuItem;
    mN4Horas: TMenuItem;
    mN8Horas: TMenuItem;
    mN12Horas: TMenuItem;
    mDia: TMenuItem;
    mN3Dias: TMenuItem;
    mSemana: TMenuItem;
    PopupMenuSeries: TPopupMenu;
    SavePictureDialog: TSavePictureDialog;
    PrinterSetupDialog: TPrinterSetupDialog;
    tbColor: TToolButton;
    tbOpciones3D: TToolButton;
    Panel1: TPanel;
    DBGrafico: TChart;
    sbZoom: TSpeedButton;
    sbSeries: TSpeedButton;
    TimerActualizarSeries: TTimer;
    N12horas1: TMenuItem;
    N1dia1: TMenuItem;
    sbZoomYmenos: TSpeedButton;
    sbZoomYmas: TSpeedButton;
    cbEscalaAuto: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure CrearSerie;
    procedure FormActivate(Sender: TObject);
    procedure sbZoomClick(Sender: TObject);
    procedure sbSeriesClick(Sender: TObject);
    procedure PopupMenuPasoClick(Sender: TObject);
    procedure AgregarQuitarSeries(Sender: TObject);
    procedure ActuralizarSeries;
    procedure CargarCamposMenu;
    procedure DBGraficoAfterDraw(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure GuardarImg(Sender: TObject);
    procedure CopiarClipBoard(Sender: TObject);
    procedure Imprimir(Sender: TObject);
    procedure ReporteWeb(Sender: TObject);
    procedure CambiarColor(Sender: TObject);
    procedure DBGraficoMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DBGraficoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Opciones3D(Sender: TObject);
    procedure TimerActualizarSeriesTimer(Sender: TObject);
    procedure ZoomYmas(Sender: TObject);
    procedure ZoomYmenos(Sender: TObject);
    procedure cbEscalaAutoClick(Sender: TObject);
  private
    { Private declarations }
    NombreSensores  : Tstrings;
  public
    { Public declarations }
    pEquipo      : ^TEquipo;
    Fecha        : String;
    PasosGrafico : array [0..9] of double;
    ListaDias    : Tstrings;
    ListaCanales : Tstrings;
    CanalOrg     : Byte; 
    TipoGrafico  : byte; //0:Lineas; 1:Area; 2:Barras; 3:Puntos
    FechaInicial : double;
    FechaActual  : double;
  end;

var
  FGraficoSensor : TFGraficoSensor;
  Iniciando      : boolean;

implementation

uses USensor;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.FormCreate(Sender: TObject);
begin
  NombreSensores  := TSTringList.Create;
  ListaDias       := TSTringList.Create;
  ListaCanales    := TSTringList.Create;

  // Genero los Nombres de Las Series
  ListaCanales.Clear;
  ListaCanales.Add('Canal 0'); ListaCanales.Add('Canal 1');ListaCanales.Add('Canal 2');
  ListaCanales.Add('Canal 3'); ListaCanales.Add('Canal 4');ListaCanales.Add('Canal 5');
  ListaCanales.Add('Canal 6'); ListaCanales.Add('Canal 7');ListaCanales.Add('Canal 8');
  ListaCanales.Add('Canal 9');

  // Genero la tabla para los pasos del gráfico
  PasosGrafico[0] := 10/86400;   PasosGrafico[1] := 30/86400;   PasosGrafico[2] := 60/86400;
  PasosGrafico[3] := 300/86400;  PasosGrafico[4] := 600/86400;  PasosGrafico[5] := 1800/86400;
  PasosGrafico[6] := 3600/86400; PasosGrafico[7] := 0.5;        PasosGrafico[8] := 1;

  Iniciando      := True;
  TipoGrafico    := 0; //Lineas
  sbZoom.Caption := PopupMenuPaso.Items[0].Caption;

  CargarCamposMenu;

  // Configuro el Grafico
  DBGrafico.Title.Text.Clear;
  DBGrafico.Title.Text.Add('EMAC MERCURY');
  DBGrafico.LeftAxis.Title.Caption    := 'Valor';
  DBGrafico.BottomAxis.Title.Caption  := 'Muestras';
  DBGrafico.Legend.Visible            := true;

  // Configuro la escala de  Eje Y
  DBGrafico.LeftAxis.Automatic        := false;//true;
  DBGrafico.LeftAxis.Maximum          := 5;
  DBGrafico.LeftAxis.Minimum          := 0;

  // Configuro la escala de  Eje X
  DBGrafico.BottomAxis.Title.Caption  := PopupMenuPaso.Items[0].Caption;
  DBGrafico.BottomAxis.Automatic      := false;
  DBGrafico.BottomAxis.Maximum        := now + 10/86400;
  DBGrafico.BottomAxis.Minimum        := now;
  DBGrafico.BottomAxis.DateTimeFormat := 'hh:nn:ss am/pm'; //'hh:nn:ss';
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i : integer;

begin
  // Libero las series del grafico
  for i:=DBGrafico.SeriesCount-1 downto 0 do begin
    DBGrafico.Series[i].Free;
  end;


  NombreSensores.Free;
  Action := caFree;
  dec(GraficosOpen,1);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.CrearSerie;
var
  Nseries     : integer;
  i,j         : integer;
  YaGraficada : boolean;
  SerieLineas : TLineSeries;
  SeriePuntos : TPointSeries;
  SerieBarras : TBarSeries;
  SerieArea   : TAreaSeries;

begin
  try
    // Libero las series que no se deben graficar
    for i:=DBGrafico.SeriesCount-1 downto 0 do begin
      j := ListaCanales.IndexOf(DBGrafico.Series[i].Title);
      if (j>=0) then if not PopupMenuSeries.Items[j].Checked then DBGrafico.Series[i].Free;
    end;

    for i:=0 to PopupMenuSeries.Items.Count-1 do begin
      if upperCase(pEquipo.Canales[i].Salida)='NUMERO' then begin
        if PopupMenuSeries.Items[i].Checked then begin
          YaGraficada := False;
          for j:=0 to DBGrafico.SeriesCount-1 do
            if (ListaCanales.Strings[i] = DBGrafico.SeriesTitleLegend(j)) then YaGraficada := True;

          if not YaGraficada then begin
            case TipoGrafico of
              1 : begin
                    SerieArea := TAreaSeries.Create(nil);
                    DBGrafico.AddSeries(SerieArea);
                  end;
              2 : begin
                    SerieBarras := TBarSeries.Create(nil);
                    SerieBarras.Marks.Visible := False;
                    DBGrafico.AddSeries(SerieBarras);
                  end;
              3 : begin
                    SeriePuntos := TPointSeries.Create(nil);
                    DBGrafico.AddSeries(SeriePuntos);
                  end;
            else //Por defecto
              SerieLineas               := TLineSeries.Create(nil);
              SerieLineas.LinePen.Width := 2;
              DBGrafico.AddSeries(SerieLineas);
            end;

            NSeries                                         := DBGrafico.SeriesCount;
            DBGrafico.Series[NSeries-1].Clear;
            DBGrafico.Series[NSeries-1].Labels.Clear;
            DBGrafico.Series[NSeries-1].Title               := ListaCanales.Strings[i]; //Nombre Campo Y
            DBGrafico.Series[NSeries-1].XValues.DateTime    := true;//False;//True;
            DBGrafico.Series[NSeries-1].YValues.DateTime    := false;

            // Cambio los ejes de ser Necesario
            DBGrafico.LeftAxis.Maximum   := max(DBGrafico.LeftAxis.Maximum, pEquipo.Canales[i].Maximo*1.05);
            DBGrafico.LeftAxis.Minimum   := min(DBGrafico.LeftAxis.Minimum, pEquipo.Canales[i].Minimo - pEquipo.Canales[i].Maximo*0.05);
            DBGrafico.LeftAxis.Increment := (DBGrafico.LeftAxis.Maximum - DBGrafico.LeftAxis.Minimum)/100;
          end;  
        end;
      end;
    end;

  except
    //
  end;

//  TimerActualizarSeriesTimer(nil);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.ActuralizarSeries;
begin
//
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.FormActivate(Sender: TObject);
begin
  Iniciando := False;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.sbZoomClick(Sender: TObject);
begin
  PopupMenuPaso.Popup(sbZoom.Left + Left+3, sbZoom.Top + Top - 140);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.sbSeriesClick(Sender: TObject);
var
  CursorPos : TPoint;

begin
  GetCursorPos(CursorPos);
//  PopupMenuSeries.Popup(CursorPos.X, CursorPos.Y);
  PopupMenuSeries.Popup(sbSeries.Left + Left+3, sbSeries.Top + Top - 157);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.PopupMenuPasoClick(Sender: TObject);
var
  i      : integer;
  maximo : double;
  minimo : double;

begin
  for i:=0 to PopupMenuPaso.Items.Count-1 do begin
    PopupMenuPaso.Items[i].Checked := False;
  end;
  (sender as TMenuItem).Checked := True;
  sbZoom.Caption                := (sender as TMenuItem).Caption;

  i      := (sender as TMenuItem).MenuIndex;
  maximo := DBGrafico.MaxXValue(DBGrafico.BottomAxis);
  minimo := DBGrafico.MinXValue(DBGrafico.BottomAxis);

  if ((maximo-minimo)> PasosGrafico[i]) then begin
    DBGrafico.BottomAxis.Maximum := maximo+PasosGrafico[i]/2;  
    DBGrafico.BottomAxis.Minimum := maximo-PasosGrafico[i]/2;
  end
  else begin
    DBGrafico.BottomAxis.Maximum := FechaInicial + PasosGrafico[i];
    DBGrafico.BottomAxis.Minimum := FechaInicial;
  end;

  DBGrafico.BottomAxis.Title.Caption := (sender as TMenuItem).Caption;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.CargarCamposMenu;
var
  NewItem : TMenuItem;
  i       : integer;

begin
  PopupMenuSeries.Items.Clear;
  for i:=0 to 9 do begin
    NewItem         := TMenuItem.Create(Self);
    NewItem.Caption := ListaCanales.Strings[i];
    NewItem.OnClick := AgregarQuitarSeries;

    PopupMenuSeries.Items.Add(NewItem);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.AgregarQuitarSeries(Sender: TObject);
begin
  if not (pEquipo^.Canales[(sender as TMenuItem).MenuIndex].Config > 0) then exit;

  if (sender as TMenuItem).Checked then
    (sender as TMenuItem).Checked := False
  else
    (sender as TMenuItem).Checked := True;

  CrearSerie;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.DBGraficoAfterDraw(Sender: TObject);
begin
  sbSeries.Left     := DBGrafico.ChartRect.Right-sbSeries.Width;
  sbZoom.Left       := DBGrafico.ChartRect.Left;
  sbZoomYmenos.Left := sbZoom.Left + sbZoom.Width + 10;
  sbZoomYmas.Left   := sbZoomYmenos.Left + sbZoomYmenos.Width + 5;
  cbEscalaAuto.Left := sbZoomYmas.Left + sbZoomYmas.Width + 10;

  sbZoom.Top        := round((DBGrafico.Height - sbZoom.Height)-DBGrafico.Height*0.03);
  sbSeries.Top      := sbZoom.Top;
  sbZoomYmenos.top  := sbZoom.Top;
  sbZoomYmas.top    := sbZoom.Top;
  cbEscalaAuto.Top  := sbZoom.Top+2;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.FormResize(Sender: TObject);
begin
//
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.GuardarImg(Sender: TObject);
var
  aux : integer;

begin
  SavePictureDialog.FileName   := 'Grafico';
  SavePictureDialog.InitialDir := GetCurrentDir;
  SavePictureDialog.Filter     := 'Archivo de Imagen (*.bmp)|*.bmp';

  if SavePictureDialog.Execute then
  begin
    if FileExists(SavePictureDialog.FileName+'.bmp') then
       if MessageDlg('El Archivo existe!! , ¿Sobre escribir?', mtConfirmation,
          [mbYes, mbNo], 0) = mrNo then  begin

         exit;
       end;

    aux := length(SavePictureDialog.FileName);
    if SavePictureDialog.FileName[aux-3] <> '.' then begin
//       DBGrafico.BottomAxis.Title.Caption := 'EMAC MERCURY';
       DBGrafico.Color                    := clWhite;
       DBGrafico.SaveToBitmapFile(SavePictureDialog.FileName+'.bmp');
       DBGrafico.Color                    := clBtnFace;
//       DBGrafico.BottomAxis.Title.Caption := ' ';
    end
    else begin
//       DBGrafico.BottomAxis.Title.Caption := 'EMAC MERCURY';
       DBGrafico.Color                    := clWhite;
       DBGrafico.SaveToBitmapFile(SavePictureDialog.FileName);
       DBGrafico.Color                    := clBtnFace;
//       DBGrafico.BottomAxis.Title.Caption := ' ';
    end;
    DBGrafico.Repaint;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.CopiarClipBoard(Sender: TObject);
begin
//  DBGrafico.BottomAxis.Title.Caption := 'EMAC MERCURY';
  DBGrafico.Color                    := clWhite;
  DBGrafico.CopyToClipboardBitmap;
  DBGrafico.Color                    := clBtnFace;
//  DBGrafico.BottomAxis.Title.Caption := ' ';
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.Imprimir(Sender: TObject);
begin
  try
    if PrinterSetupDialog.Execute then begin
  //     DBGrafico.BottomAxis.Title.Caption   := 'EMAC MERCURY';
       DBGrafico.Color                      := clWhite;
       DBGrafico.PrintProportional          := False;
       DBGrafico.PrintMargins.TopLeft.x     := 0;
       DBGrafico.PrintMargins.TopLeft.y     := 0;
       DBGrafico.PrintMargins.BottomRight.x := 0;
       DBGrafico.PrintMargins.BottomRight.y := 0;
       DBGrafico.PrintLandscape;
       Repaint;
       DBGrafico.Color                      := clBtnFace;
  //     DBGrafico.BottomAxis.Title.Caption   := ' ';
     end;
  except
    // Muestro el cartel de Error
    MessageBox(Handle,pchar('No existe ninguna impresora instalada.'),
               PChar('EMAC Mercury'), MB_OK or MB_ICONERROR);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.ReporteWeb(Sender: TObject);
var
  i           : integer;
  Nombre      : String;
  auxTStrings : Tstrings;
  F           : TextFile;

begin
  if not (DBGrafico.SeriesCount>0) then exit;

  auxTStrings := TStringList.create;
  Nombre      := Mercury.DirTemp + 'EMAC_MERCURY' + '.html';

  auxTStrings.Add('<HTML>');
  auxTStrings.Add('<HEAD>');
  auxTStrings.Add('<TITLE>Reporte de EMAC MERCURY</TITLE>');
  auxTStrings.Add('</HEAD>');
  auxTStrings.Add('<BODY BGCOLOR="#FFFFFF">');

  auxTStrings.Add('<TABLE BORDER="0" WIDTH="100%"><TR>');
  auxTStrings.Add('<TD ALIGN="left"><FONT SIZE="2"><EM>EMAC MERCURY</EM></FONT></TD>');
  auxTStrings.Add('<TD ALIGN="center"><FONT SIZE="4"><EM>'+ 'EMAC MERCURY' +'</EM></FONT></TD>');
  auxTStrings.Add('<TD ALIGN="right"><FONT SIZE="2"><EM>'+ DateTimeToStr(now)+'</EM></FONT></TD>');
  auxTStrings.Add('</TR></TABLE><HR>');

  auxTStrings.Add('<P>');
  auxTStrings.Add('<center> <img src="ImgGrafico.bmp"> </center>');
  auxTStrings.Add('<P>');

  auxTStrings.Add('<HR>');
  auxTStrings.Add('<TABLE BORDER="0" WIDTH="100%"><TR><TD ALIGN="RIGHT" CELLSPACING="0">');
  auxTStrings.Add('<FONT SIZE="2">Creado por <A HREF="http://iado.criba.edu.ar">EMAC MERCURY</A></FONT>');
  auxTStrings.Add('</TD></TR></TABLE>');
  auxTStrings.Add('</FONT>');
  auxTStrings.Add('</BODY>');
  auxTStrings.Add('</HTML>');

  try
    AssignFile(F, Nombre);
    Rewrite(F);
    for i:=0 to auxTStrings.Count-1 do Writeln(F,auxTStrings.Strings[i]);
    CloseFile(F);

//    DBGrafico.BottomAxis.Title.Caption := 'Muestras';
    DBGrafico.Color                    := clWhite;
    DBGrafico.SaveToBitmapFile(Mercury.DirTemp+'ImgGrafico.bmp');
    DBGrafico.Color                    := clBtnFace;
//    DBGrafico.BottomAxis.Title.Caption := 'Muestras';


    ShellExecute(handle,'open',Pchar(Nombre),nil,nil,SW_SHOWNORMAL);
  except
    CloseFile(F);
    MessageBox(Handle,Pchar('No se puede guardar el archivo'+#13+'Compruebe que no es solo lectura'),
              'IadoDB',MB_OK or MB_ICONINFORMATION	);
  end;
  auxTStrings.Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.CambiarColor(Sender: TObject);
var i,index : integer;
    Color   : TColor;
    Ejecuto : Boolean;

begin
   FColor := TFColor.Create(nil);

   FColor.CBSeries.Items.Clear;
   FColor.CBSeries.Items.Insert(0,'Aplicar color a todas las Series');
   for i:=1 to DBGrafico.SeriesCount do
      FColor.CBSeries.Items.Insert(i,DBGrafico.Series[i-1].Title);
   FColor.CBSeries.ItemIndex := 0;
   Fcolor.Principal(Ejecuto,Color,index);

   if Ejecuto and (index = 0)then
     for i:=0 to DBGrafico.SeriesCount-1 do
      DBGrafico.Series[i].SeriesColor := Color;

   if Ejecuto and (index <> 0)then
     DBGrafico.Series[index-1].SeriesColor := Color;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.DBGraficoMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
   if (DBGrafico.seriescount >0) then
   begin
//    DBGrafico.ShowHint := True;
    if DBGrafico.Series[0].XValues.DateTime then begin
      DBGrafico.Hint := FormatDateTime('hh:nn:ss am/pm', DBGrafico.Series[0].XScreenToValue(X))
                        +',  '+ FormatFloat('#.0000',DBGrafico.Series[0].YScreenToValue(Y));
    end
    else
      DBGrafico.Hint := FormatFloat('#.0000',DBGrafico.Series[0].XScreenToValue(X))
                        +'  '+ FormatFloat('#.0000',DBGrafico.Series[0].YScreenToValue(Y));
   end
   else DBGrafico.ShowHint := False;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.DBGraficoMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //TMouseButton = (mbLeft, mbRight, mbMiddle);
  if Button = mbLeft  then DBGrafico.ShowHint := True;
  if Button = mbRight then DBGrafico.ShowHint := False;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.Opciones3D(Sender: TObject);
begin
  FormOpciones3D            := TFormOpciones3D.Create(Self);
  FormOpciones3D.Caption    := 'Opciones 3D';
  FormOpciones3D.pDBGrafico := @DBGrafico;
  FormOpciones3D.ShowModal;

//  DBGrafico.View3DOptions.Tilt := 25;   1;100
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.TimerActualizarSeriesTimer(Sender: TObject);
var
  i      : integer;
  Canal  : integer;
  DTmax  : Double;
  DTmin  : Double;
  dT     : Double; 

begin
  FechaActual := now;

  for i:=0 to DBGrafico.SeriesCount-1 do begin
    Canal := ListaCanales.IndexOf(DBGrafico.SeriesTitleLegend(i));

    if (pEquipo^.Canales[Canal].Config > 0) then begin
      DBGrafico.Series[i].AddXY(FechaActual, pEquipo^.Canales[Canal].ValorNum);
    end
    else begin   // Lo borro de la lista
      PopupMenuSeries.Items[Canal].Checked := false;
      CrearSerie;
    end;
  end;

  if (DBGrafico.SeriesCount > 0) then begin
    DTmax := DBGrafico.BottomAxis.Maximum;
    DTmin := DBGrafico.BottomAxis.Minimum;
    dT    := (DTmax - DTmin)/10;

    if FechaActual > (DTmax - dT) then begin
      DBGrafico.BottomAxis.Maximum := FechaActual + dT;
      DBGrafico.BottomAxis.Minimum := (DBGrafico.BottomAxis.Maximum - DTmax) + DTmin; 
    end;
  end;

  // Recargo la cuenta del Timer, 500ms 
  TimerActualizarSeries.Enabled := true;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.ZoomYmas(Sender: TObject);
var
  ymin, ymax : double;

begin
  ymax := DBGrafico.LeftAxis.Maximum + abs(DBGrafico.LeftAxis.Maximum*0.01);
  ymin := DBGrafico.LeftAxis.Minimum - abs(DBGrafico.LeftAxis.Maximum*0.01);

  if (ymax > ymin) then begin
    DBGrafico.LeftAxis.Maximum := ymax;
    DBGrafico.LeftAxis.Minimum := ymin;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.ZoomYmenos(Sender: TObject);
var
  ymin, ymax : double;

begin
  ymax := DBGrafico.LeftAxis.Maximum - abs(DBGrafico.LeftAxis.Maximum*0.01);
  ymin := DBGrafico.LeftAxis.Minimum + abs(DBGrafico.LeftAxis.Maximum*0.01);

  if (ymax > ymin) then begin
    DBGrafico.LeftAxis.Maximum := ymax;
    DBGrafico.LeftAxis.Minimum := ymin;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TFGraficoSensor.cbEscalaAutoClick(Sender: TObject);
begin
  if cbEscalaAuto.Checked then DBGrafico.LeftAxis.Automatic := true
  else DBGrafico.LeftAxis.Automatic := false;
end;

////////////////////////////////////////////////////////////////////////////////
end.


