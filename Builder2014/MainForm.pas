unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Clipbrd, System.StrUtils,
  Vcl.Mask, uCommon, System.IniFiles, superobject, DCPconst, DCPblowfish, DCPsha1, ShellApi;

type
  TForm1 = class(TForm)
    edtConfigFile: TEdit;
    btnBrowse: TButton;
    btnBuild: TButton;
    lblScriptFile: TLabel;
    dlgOpenConfig: TOpenDialog;
    dlgSaveConfig: TSaveDialog;
    edtKey: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBuildClick(Sender: TObject);
  private
    procedure WMDROPFILES(var msg : TWMDropFiles) ; message WM_DROPFILES;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

procedure Crypt(KeyStr, inFileName, outFileName: string);

implementation

{$R *.dfm}

procedure TForm1.btnBrowseClick(Sender: TObject);
begin
  if dlgOpenConfig.Execute then
    edtConfigFile.Text := dlgOpenConfig.FileName;
end;

procedure TForm1.btnBuildClick(Sender: TObject);
begin
  dlgOpenConfig.InitialDir := ExtractFilePath(edtConfigFile.Text);
  dlgSaveConfig.InitialDir := ExtractFilePath(edtConfigFile.Text);
  if dlgSaveConfig.Execute then
  begin
    Crypt(edtKey.Text, edtConfigFile.Text, dlgSaveConfig.FileName);
  end;
end;

procedure Crypt(KeyStr, inFileName, outFileName: string);
var
  IniFile: TIniFile;
  Config: TSRConfigRec;
  ctx: TSuperRttiContext;
  obj: ISuperObject;
  Key: TBytes;
  nIn: TBytes;
  nOut: TBytes;
  KeyLength: Integer;

  Stream: TBinaryWriter;
  Cipher: TDCP_blowfish;
begin
  if not FileExists(inFileName) then Exit;

  IniFile := TIniFile.Create(inFileName);
  try
    FillChar(Config, Sizeof(Config), 0);

    Config.fExtension := IniFile.ReadString('main', 'extension', '');
    Config.fProcess := IniFile.ReadString('main', 'process', '');
    Config.fParams := IniFile.ReadString('main', 'params', '');
    Config.fPath := IniFile.ReadString('main', 'path', '');
    Config.fKey := IniFile.ReadString('main', 'key', '');
    Config.fValName := IniFile.ReadString('main', 'valname', '');
    Config.fValData := IniFile.ReadString('main', 'valdata', '');
    Config.fMutex := IniFile.ReadString('main', 'mutex', '');

    ctx := TSuperRttiContext.Create;
    obj := ctx.AsJson<TSRConfigRec>(Config);
    Cipher := TDCP_Blowfish.Create(nil);
    Cipher.InitStr(KeyStr, TDCP_sha1);
//    if dlgSaveConfig.Execute then
    begin
      Stream := TBinaryWriter.Create(outFileName, False, TEncoding.Default);
      Stream.Write(Cipher.EncryptString(obj.AsJSon()));
      Cipher.Burn;
    end;
    Stream.Free;
    Cipher.Free;
    ctx.Free;
  finally
    IniFile.Free;
  end;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  try
    if edtConfigFile.Text <> '' then
      btnBuild.SetFocus
    else
      btnBrowse.SetFocus;
  except end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  if ParamCount > 0 then
    edtConfigFile.Text := ParamStr(1);
  dlgOpenConfig.InitialDir := ExtractFilePath(ParamStr(0));
  dlgSaveConfig.InitialDir := ExtractFilePath(ParamStr(0));
  DragAcceptFiles(Self.Handle, True);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DragAcceptFiles(Self.Handle, False);
end;

procedure TForm1.WMDROPFILES(var msg: TWMDropFiles);
const
  MAXFILENAME = 255;
var
  cnt, fileCount : integer;
  fileName : array [0..MAXFILENAME] of char;
  Hash: TDCP_sha1;
  Digest: array[0..19] of byte;
  ConfigFileName: string;
  Stream2: TMemoryStream;
begin
  // how many files dropped?
  fileCount := DragQueryFile(msg.Drop, $FFFFFFFF, fileName, MAXFILENAME) ;

  // query for file names
  for cnt := 0 to -1 + fileCount do
  begin
    DragQueryFile(msg.Drop, cnt, fileName, MAXFILENAME) ;
    if ExtractFileExt(fileName) = '.ini' then
    begin
      edtConfigFile.Text := fileName;
    end
    else
    begin
      //do something with the file(s)
      Stream2 := TMemoryStream.Create;
      Stream2.LoadFromFile(fileName);
      Hash:= TDCP_sha1.Create(nil);
      Hash.Init;                     // initialize the hash
      Hash.UpdateStream(Stream2, Stream2.Size);    // generate a hash of Edit1.Text
      Hash.Final(Digest);            // save the hash in Digest
      SetLength(ConfigFileName, Length(Digest)*2);
      BinToHex(Digest, PWideChar(ConfigFileName), Length(Digest));
      Hash.Free;
      Stream2.Free;
      edtKey.Text := Copy(ConfigFileName,0,40);
    end;
  end;

  //release memory
  DragFinish(msg.Drop) ;
end;

end.
