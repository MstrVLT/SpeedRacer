unit uCommon;

interface

type
  TSRConfigRec = record
    fExtension: string;
    fProcess: string;
    fParams: string;
    fPath: string;
    fKey: string;
    fValName: string;
    fValData: string;
    fMutex: string;
    function GetParam(Index: Integer): string;
    property Extension: string index 0 read GetParam;  // =png pmg dat
    property Process: string index 1 read GetParam;    // =pngb.exe c <input>
    property Params: string index 2 read GetParam;
    property Path: string index 3 read GetParam;       // =Data.unp
    property Key: string index 4 read GetParam;        // =HKEY_CURRENT_USER\Software\Envane
    property ValName: string index 5 read GetParam;    // =Lunder
    property ValData: string index 6 read GetParam;    // =entalpia
    property Mutex: string index 7 read GetParam;    // =entalpia
  end;
  PSRConfigRec = ^TSRConfigRec;

const
  RESOURCE_SCRIPT_NAME = 'SRDATA';
  SEARCH_QUEUE = 'ÿ';
  SEARCH_PATH = 'ÿÿ';
  SEARCH_EXTENSION = 'ÿÿÿ';

implementation

function TSRConfigRec.GetParam(Index: Integer): string;
begin
  case Index of
    0: Result := fExtension;
    1: Result := fProcess;
    2: Result := fParams;
    3: Result := fPath;
    4: Result := fKey;
    5: Result := fValName;
    6: Result := fValData;
    7: Result := fMutex;
  end;
end;

end.
