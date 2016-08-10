program SRB;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1},
  uCommon in '..\Common\uCommon.pas';

{$R *.res}

begin
  if ParamCount > 1 then
  begin
    if ParamCount = 3 then
      Crypt(ParamStr(1), ParamStr(2), ParamStr(3));
    Exit;
  end;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
