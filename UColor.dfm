object FColor: TFColor
  Left = 268
  Top = 209
  BorderStyle = bsDialog
  Caption = 'Seleccione el Color Deseado'
  ClientHeight = 100
  ClientWidth = 324
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 0
    Top = 64
    Width = 329
    Height = 2
  end
  object BClose: TSpeedButton
    Left = 224
    Top = 72
    Width = 89
    Height = 25
    Caption = '&Cerrar'
    Flat = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = BCloseClick
  end
  object BSColor: TSpeedButton
    Left = 12
    Top = 72
    Width = 89
    Height = 25
    Caption = 'Elegir Color...'
    Flat = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = BSColorClick
  end
  object CBSeries: TComboBox
    Left = 40
    Top = 16
    Width = 249
    Height = 22
    Style = csOwnerDrawFixed
    ItemHeight = 16
    TabOrder = 0
  end
  object ColorDialog1: TColorDialog
    Ctl3D = True
    Top = 16
  end
end
