unit UDataModule;

interface

uses
  SysUtils, Classes, ImgList, Controls, Dialogs;

type
  TDataModule1 = class(TDataModule)
    ImageList18x18: TImageList;
    ImageList32x32: TImageList;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.dfm}

end.
