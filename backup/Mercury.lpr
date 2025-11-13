program Mercury;

uses
  Forms,
  Uprincipal in 'Uprincipal.pas' {Fprincipal},
  UEquipo in 'UEquipo.pas',
  PuertoSerie in 'PuertoSerie.pas',
  UUtiles in 'UUtiles.pas',
  UPresentacion in 'UPresentacion.pas' {FPresentacion},
  USensor in 'USensor.pas',
  UPreferencias in 'UPreferencias.pas' {FPreferencias},
  UGrafico in 'UGrafico.pas' {FGraficoSensor},
  UOpciones3D in 'UOpciones3D.pas' {FormOpciones3D},
  UColor in 'UColor.pas' {FColor},
  UDataModule in 'UDataModule.pas' {DataModule1: TDataModule},
  UFormulas in 'UFormulas.pas',
  UCalculoParam in 'UCalculoParam.pas' {FCalculoParam},
  UConexionesRemotas in 'UConexionesRemotas.pas' {FConexionesRemotas},
  UConexiones in 'UConexiones.pas',
  UConexionAuto in 'UConexionAuto.pas' {FConexionAuto},
  UConfiguracionInternet in 'UConfiguracionInternet.pas' {FConfiguracionInternet},
  UServerSocket in 'UServerSocket.pas',
  UEquipoInternet in 'UEquipoInternet.pas',
  UDiaJuliano in 'UDiaJuliano.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFprincipal, Fprincipal);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.Run;
end.
