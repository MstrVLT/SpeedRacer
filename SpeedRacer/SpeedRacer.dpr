program SpeedRacer;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IniFiles,
  System.Win.Registry,
  Winapi.Windows,
  OtlParallel,
  OtlCommon,
  OtlTask,
  OtlTaskControl,
  OtlCollections,
  Winapi.ShellAPI,
  superobject,
  System.Classes,
  uCommon in '..\Common\uCommon.pas',
  DCPconst in '..\Common\DCPconst.pas',
  DCPblowfish in '..\Common\Ciphers\DCPblowfish.pas',
  DCPcrypt2 in '..\Common\DCPcrypt2.pas',
  DCPbase64 in '..\Common\DCPbase64.pas',
  DCPblockciphers in '..\Common\DCPblockciphers.pas',
  DCPsha1 in '..\Common\Hashes\DCPsha1.pas';
type
  TSRConfig = class
  private
    fConfig: TSRConfigRec;
  public
    function Load(ACheckProc: TProc<PSRConfigRec>): Boolean;
    property Config: TSRConfigRec read fConfig;
  end;

  TSRCore = class
    constructor Create;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

procedure Check(var AConfig: TSRConfigRec); inline;
var
  Mutex: THandle;
begin
  Mutex := CreateMutex(nil, True, PWideChar(AConfig.Mutex));
  if not ((Mutex = 0) OR (GetLastError = ERROR_ALREADY_EXISTS)) then
     raise Exception.Create(ParamStr(0));
end;

function TSRConfig.Load(ACheckProc: TProc<PSRConfigRec>): Boolean;
var
  IniFile: TIniFile;
  ConfigFileName: string;
  ctx: TSuperRttiContext;
  Stream: TBinaryReader;
  Stream2: TMemoryStream;
  Cipher: TDCP_Blowfish;
  Hash: TDCP_sha1;
  Digest: array[0..19] of byte;
begin
//  if ParamCount = 0 then raise Exception.Create(ParamStr(0));
  ConfigFileName := ChangeFileExt(ParamStr(0), '.sr');

  ctx := TSuperRttiContext.Create;
  try
    Stream2 := TMemoryStream.Create;
    Stream := TBinaryReader.Create(ConfigFileName, TEncoding.Default);

    Cipher := TDCP_Blowfish.Create(nil);
//    Cipher.InitStr('passw', TDCP_sha1);
//    asm
//      nop
//      nop
//      nop
//      nop
//      nop
//      nop
//    end;
    try
      Hash:= TDCP_sha1.Create(nil);
      Hash.Init;                     // initialize the hash
      Stream2.LoadFromFile(ChangeFileExt(ConfigFileName, ExtractFileExt(ParamStr(0))));
      Hash.UpdateStream(Stream2, Stream2.Size);    // generate a hash of Edit1.Text
      Hash.Final(Digest);            // save the hash in Digest
      SetLength(ConfigFileName, Length(Digest)*2);
      BinToHex(Digest, PWideChar(ConfigFileName), Length(Digest));
      Cipher.InitStr(Copy(ConfigFileName,0,40), TDCP_sha1);
//      Writeln(Copy(ConfigFileName,0,40));
      Hash.Free;
      fConfig := ctx.AsType<TSRConfigRec>(SO(Cipher.DecryptString(Stream.ReadString)));
//      Writeln(Cipher.DecryptString(AnsiString(Stream.ReadString)));
    except end;
    Cipher.Burn;
    Cipher.Free;
    ACheckProc(@fConfig);
  finally
    ctx.free;
  end;

//  IniFile := TIniFile.Create(ConfigFileName);
//  try
//    FillChar(fConfig, Sizeof(fConfig), 0);
//    fConfig.Key := IniFile.ReadString('main', 'key', '');
//    fConfig.ValName := IniFile.ReadString('main', 'valname', '');
//    fConfig.ValData := IniFile.ReadString('main', 'valdata', '');
//    ACheckProc(@fConfig);
//    if not (fConfig.Key = '') then raise Exception.Create(ParamStr(0));
//    fConfig.Extension := IniFile.ReadString('main', 'extension', '');
//    if not (fConfig.ValName = '') then raise Exception.Create(ParamStr(0));
//    fConfig.Process := ExpandFileName(IniFile.ReadString('main', 'process', ''));
//    fConfig.Params := IniFile.ReadString('main', 'params', '');
//    if not (fConfig.ValData = '') then raise Exception.Create(ParamStr(0));
//    fConfig.Path := ExpandFileName(IniFile.ReadString('main', 'path', ''));
////    if fConfig.ValData = '' then raise Exception.Create(ParamStr(0));
//  finally
//    IniFile.Free;
//  end;
end;

var
  Config: TSRConfig;
  Core: TSRCore;
  MaxExecuting: Integer;

{ TSRCore }

procedure TSRCore.AfterConstruction;
begin
  inherited;
end;

procedure FileSearch(const PathName: string; const Extensions: string; FindFileProc: TProc<string>); inline;
const
  FileMask = '*.*';
var
  Rec: System.SysUtils.TSearchRec;
  Path: string;
begin
  Path := IncludeTrailingBackslash(PathName);
  if System.SysUtils.FindFirst(Path + FileMask, faAnyFile - faDirectory, Rec) = 0 then
    try
      repeat
        if AnsiPos(ExtractFileExt(Rec.Name), Extensions) > 0 then
          FindFileProc(Path + Rec.Name);
      until System.SysUtils.FindNext(Rec) <> 0;
    finally
      System.SysUtils.FindClose(Rec);
    end;

  if System.SysUtils.FindFirst(Path + '*.*', faDirectory, Rec) = 0 then
    try
      repeat
        if ((Rec.Attr and faDirectory) <> 0) and (Rec.Name <> '.') and
          (Rec.Name <> '..') then
          FileSearch(Path + Rec.Name, Extensions, FindFileProc);
      until System.SysUtils.FindNext(Rec) <> 0;
    finally
      System.SysUtils.FindClose(Rec);
    end;
end;

procedure Search(const task: IOmniTask);
var
  Queue : IOmniBlockingCollection;
  PathName,
  Extensions: string;
begin
  Queue := task.Param[SEARCH_QUEUE].AsInterface as IOmniBlockingCollection;
  PathName := task.Param[SEARCH_PATH].AsString;
  Extensions := task.Param[SEARCH_EXTENSION].AsString;
  FileSearch(PathName, Extensions,
    procedure(Arg1: string)
    begin
      Queue.Add(Arg1);
    end);
  Queue.CompleteAdding;
end;

function ShellExecuteAndWait(FileName: string; Params: string): Boolean; inline;
var
  exInfo: TShellExecuteInfo;
  Ph: DWORD;
begin
  try
    FillChar(exInfo, SizeOf(exInfo), 0);
    with exInfo do
    begin
      cbSize := SizeOf(exInfo);
      fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_DDEWAIT or SEE_MASK_NO_CONSOLE;
      Wnd := 0;
      exInfo.lpVerb := 'open';
      exInfo.lpParameters := PWideChar(Params);
      lpFile := PWideChar(FileName);
      nShow := SW_HIDE;
    end;

    if ShellExecuteEx(@exInfo) then Ph := exInfo.hProcess else Exit(True);

    while WaitForSingleObject(exInfo.hProcess, 50) <> WAIT_OBJECT_0 do
      ;
    CloseHandle(Ph);
  finally
    FillChar(Ph, SizeOf(Ph), 0);
    FillChar(exInfo, SizeOf(exInfo), 0);
  end;
  Result := True;
end;

procedure SearchAndRun(StartFolder, Extension, ExecuteProcess, ExecuteParams: string);
var
  outQueue : IOmniBlockingCollection;
begin
  outQueue := TOmniBlockingCollection.Create;

  CreateTask(Search)
    .SetParameter(SEARCH_QUEUE, outQueue)
    .SetParameter(SEARCH_PATH, StartFolder)
    .SetParameter(SEARCH_EXTENSION, Extension)
    .Run;

  Parallel.ForEach<string>(outQueue)
      .NumTasks(MaxExecuting)
      .Execute(
        procedure(const task: IOmniTask; const value: string)
        var
          process, param: string;
        begin
          try
            process := ExecuteProcess;
            param := Format(ExecuteParams, [value,
                                            ExtractFileDrive(value),
                                            ExtractFileDir(value),
                                            ChangeFileExt(ExtractFileName(value), ''),
                                            ExtractFileExt(value)]);
            ShellExecuteAndWait(process, param);
          finally
            SetLength(process, 0);
            SetLength(param, 0);
          end;
        end );
end;

procedure TSRCore.BeforeDestruction;
begin
  SearchAndRun(ExpandFileName(Config.Config.Path), Config.Config.Extension, ExpandFileName(Config.Config.Process), Config.Config.Params);
  inherited;
end;

constructor TSRCore.Create;
begin

end;

begin
  try
    Config := TSRConfig.Create;
    try
      Core := TSRCore.Create;
      try
        Config.Load(
          procedure(AConfig: PSRConfigRec)
          begin
            Check(AConfig^);
          end);
//    Config.fProcess := ExpandFileName(IniFile.ReadString('main', 'process', ''));
//    Config.fParams := IniFile.ReadString('main', 'params', '');
//    Config.fPath := ExpandFileName(IniFile.ReadString('main', 'path', ''));
        MaxExecuting := StrToIntDef(ParamStr(1), Environment.Process.Affinity.Count - 1);
//      SearchAndRun(ExpandFileName(Config.Config.Path), Config.Config.Extension, ExpandFileName(Config.Config.Process), Config.Config.Params);
        Core.Free;
      except
//        Writeln(Config.Config.Path);
      end;

    finally
      Config.Free;
    end;
    { TODO -oUser -cConsole Main : Insert code here }
  except end;
end.
