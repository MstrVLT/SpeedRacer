object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SpeedRacer Builder'
  ClientHeight = 105
  ClientWidth = 395
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    395
    105)
  PixelsPerInch = 96
  TextHeight = 13
  object lblScriptFile: TLabel
    Left = 8
    Top = 11
    Width = 42
    Height = 13
    Caption = #1050#1086#1085#1092#1080#1075':'
  end
  object edtConfigFile: TEdit
    Left = 56
    Top = 8
    Width = 302
    Height = 22
    Anchors = [akLeft, akTop, akRight]
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object btnBrowse: TButton
    Left = 364
    Top = 8
    Width = 23
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 1
    OnClick = btnBrowseClick
  end
  object btnBuild: TButton
    Left = 8
    Top = 63
    Width = 379
    Height = 34
    Anchors = [akLeft, akTop, akRight]
    Caption = #1057#1086#1079#1076#1072#1090#1100'  SpeedRacer'
    TabOrder = 2
    OnClick = btnBuildClick
  end
  object edtKey: TEdit
    Left = 8
    Top = 36
    Width = 379
    Height = 21
    TabOrder = 3
  end
  object dlgOpenConfig: TOpenDialog
    FileName = 'SpeedRacer.ini'
    Filter = 'Speed Racer Config|*.ini'
    InitialDir = 'C:'
    Left = 152
  end
  object dlgSaveConfig: TSaveDialog
    FileName = 'SpeedRacer.sr'
    Filter = 'Speed Racer Crypt Config|*.sr'
    InitialDir = 'C:'
    Left = 184
    Top = 48
  end
end
