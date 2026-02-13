object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'FRX Image Viewer'
  ClientHeight = 700
  ClientWidth = 1000
  Color = clBtnFace
  Constraints.MinHeight = 600
  Constraints.MinWidth = 800
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 13
  object lblTitle: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 994
    Height = 21
    Align = alTop
    Caption = 'FRX Images from VB Decompiler'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    ExplicitWidth = 246
  end
  object Splitter1: TSplitter
    Left = 250
    Top = 27
    Width = 5
    Height = 650
    ExplicitLeft = 248
    ExplicitTop = 29
    ExplicitHeight = 648
  end
  object lvImages: TListView
    Left = 0
    Top = 27
    Width = 250
    Height = 650
    Align = alLeft
    Columns = <>
    DoubleBuffered = True
    IconOptions.AutoArrange = True
    ParentDoubleBuffered = False
    TabOrder = 0
    OnSelectItem = lvImagesSelectItem
  end
  object pnlPreview: TPanel
    Left = 255
    Top = 27
    Width = 745
    Height = 650
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object imgPreview: TImage
      Left = 0
      Top = 0
      Width = 745
      Height = 614
      Align = alClient
      Center = True
      Proportional = True
      ExplicitHeight = 652
    end
    object pnlSaveButton: TPanel
      Left = 0
      Top = 614
      Width = 745
      Height = 36
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        745
        36)
      object btnSaveToFile: TButton
        Left = 635
        Top = 6
        Width = 100
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Save to file'
        TabOrder = 0
        OnClick = btnSaveToFileClick
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 677
    Width = 1000
    Height = 23
    Panels = <
      item
        Bevel = pbNone
        Text = 'Active image'
        Width = 150
      end
      item
        Bevel = pbNone
        Width = 50
      end>
    OnDrawPanel = StatusBarDrawPanel
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'bmp'
    Filter = 
      'Bitmap files (*.bmp)|*.bmp|PNG files (*.png)|*.png|JPEG files (*' +
      '.jpg)|*.jpg|GIF files (*.gif)|*.gif|Icon files (*.ico)|*.ico|Cur' +
      'sor files (*.cur)|*.cur|All files (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 328
    Top = 96
  end
end
