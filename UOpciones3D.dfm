object FormOpciones3D: TFormOpciones3D
  Left = 402
  Top = 305
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Opciones 3D de " "'
  ClientHeight = 270
  ClientWidth = 433
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 3
    Top = 232
    Width = 428
    Height = 2
  end
  object sbCerrar: TSpeedButton
    Left = 328
    Top = 241
    Width = 90
    Height = 25
    Caption = 'Cerrar'
    Flat = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = sbCerrarClick
  end
  object GroupBox1: TGroupBox
    Left = 16
    Top = 10
    Width = 401
    Height = 205
    TabOrder = 0
    object Label1: TLabel
      Left = 176
      Top = 24
      Width = 27
      Height = 13
      Caption = 'Zoom'
    end
    object Label2: TLabel
      Left = 160
      Top = 57
      Width = 43
      Height = 13
      Caption = 'Rotaci'#243'n'
    end
    object Label3: TLabel
      Left = 156
      Top = 81
      Width = 47
      Height = 13
      Caption = 'Elevaci'#243'n'
    end
    object Label4: TLabel
      Left = 144
      Top = 113
      Width = 58
      Height = 13
      Caption = 'Horiz. Offset'
    end
    object Label5: TLabel
      Left = 149
      Top = 137
      Width = 53
      Height = 13
      Caption = 'Vert. Offset'
    end
    object Label6: TLabel
      Left = 147
      Top = 169
      Width = 56
      Height = 13
      Caption = 'Perspectiva'
    end
    object LZoom: TLabel
      Left = 360
      Top = 26
      Width = 26
      Height = 13
      Caption = '100%'
    end
    object LRotacion: TLabel
      Left = 360
      Top = 57
      Width = 18
      Height = 13
      Caption = '333'
    end
    object LElevacion: TLabel
      Left = 360
      Top = 82
      Width = 18
      Height = 13
      Caption = '311'
    end
    object LHorizOffset: TLabel
      Left = 360
      Top = 112
      Width = 6
      Height = 13
      Caption = '0'
    end
    object LVertOffset: TLabel
      Left = 360
      Top = 137
      Width = 6
      Height = 13
      Caption = '0'
    end
    object LPerspectiva: TLabel
      Left = 360
      Top = 168
      Width = 6
      Height = 13
      Caption = '0'
    end
    object Label7: TLabel
      Left = 44
      Top = 26
      Width = 69
      Height = 13
      Caption = '3 Dimensiones'
    end
    object Label8: TLabel
      Left = 44
      Top = 58
      Width = 46
      Height = 13
      Caption = 'Ortogonal'
    end
    object Label9: TLabel
      Left = 44
      Top = 90
      Width = 57
      Height = 13
      Caption = 'Zoom Texto'
    end
    object sbrZoom: TScrollBar
      Left = 216
      Top = 24
      Width = 140
      Height = 16
      Max = 500
      Min = 1
      PageSize = 0
      Position = 100
      TabOrder = 0
      OnChange = sbrZoomChange
    end
    object sbrRotacion: TScrollBar
      Left = 216
      Top = 56
      Width = 140
      Height = 16
      Max = 360
      Min = 270
      PageSize = 0
      Position = 333
      TabOrder = 1
      OnChange = sbrRotacionChange
    end
    object sbrElevacion: TScrollBar
      Left = 216
      Top = 80
      Width = 140
      Height = 16
      Max = 360
      Min = 270
      PageSize = 0
      Position = 311
      TabOrder = 2
      OnChange = sbrElevacionChange
    end
    object sbrHorzOffset: TScrollBar
      Left = 216
      Top = 112
      Width = 140
      Height = 16
      Max = 1500
      Min = -1500
      PageSize = 0
      TabOrder = 3
      OnChange = sbrHorzOffsetChange
    end
    object sbrVertOffset: TScrollBar
      Left = 216
      Top = 136
      Width = 140
      Height = 16
      Max = 1500
      Min = -1500
      PageSize = 0
      TabOrder = 4
      OnChange = sbrVertOffsetChange
    end
    object sbrPerspectiva: TScrollBar
      Left = 216
      Top = 168
      Width = 140
      Height = 16
      PageSize = 0
      TabOrder = 5
      OnChange = sbrPerspectivaChange
    end
    object cb3D: TCheckBox
      Left = 24
      Top = 24
      Width = 17
      Height = 17
      TabOrder = 6
      OnClick = cb3DClick
    end
    object cbOrtogonal: TCheckBox
      Left = 24
      Top = 56
      Width = 17
      Height = 17
      TabOrder = 7
      OnClick = cbOrtogonalClick
    end
    object cbZoomTexto: TCheckBox
      Left = 24
      Top = 88
      Width = 17
      Height = 17
      TabOrder = 8
      OnClick = cbZoomTextoClick
    end
  end
end
