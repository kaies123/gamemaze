object AboutBox: TAboutBox
  Left = 200
  Top = 108
  BorderStyle = bsDialog
  Caption = 'OpenGL info'
  ClientHeight = 260
  ClientWidth = 298
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 281
    Height = 201
    BevelInner = bvRaised
    BevelOuter = bvLowered
    ParentColor = True
    TabOrder = 0
    object RendererLabel: TLabel
      Left = 8
      Top = 16
      Width = 47
      Height = 13
      Caption = 'Renderer:'
    end
    object VersionLabel: TLabel
      Left = 8
      Top = 64
      Width = 38
      Height = 13
      Caption = 'Version:'
    end
    object VendorLabel: TLabel
      Left = 8
      Top = 40
      Width = 37
      Height = 13
      Caption = 'Vendor:'
    end
    object Renderer: TLabel
      Left = 72
      Top = 16
      Width = 3
      Height = 13
    end
    object Vendor: TLabel
      Left = 72
      Top = 40
      Width = 3
      Height = 13
    end
    object Version: TLabel
      Left = 72
      Top = 64
      Width = 3
      Height = 13
    end
    object ExtensionsLabel: TLabel
      Left = 8
      Top = 88
      Width = 54
      Height = 13
      Caption = 'Extensions:'
    end
    object Extensions: TListBox
      Left = 24
      Top = 104
      Width = 233
      Height = 89
      ItemHeight = 13
      TabOrder = 0
    end
  end
  object OKButton: TButton
    Left = 111
    Top = 220
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
end
