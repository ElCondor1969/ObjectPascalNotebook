unit uUtilities;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function GenerateUUID: string;

implementation

function GenerateUUID: string;
var
  Guid: TGUID;  
begin
  CreateGUID(Guid);
  Result := GUIDToString(Guid);
end;

end.
