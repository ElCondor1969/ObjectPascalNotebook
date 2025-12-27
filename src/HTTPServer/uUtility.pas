unit uUtility;

interface

uses
  Classes, SysUtils, DateUtils, Variants, JSON, dwsDataContext, dwsExprs, dwsInfo;

type
  TVarRecArray=array of TVarRec;

function AnsiPosEx(SottoStringa,Stringa:string;Posizione:integer=1):integer;
procedure RaiseException(const AMessage:string);overload;
procedure RaiseException(const AMessage:string;const Args:array of const);overload;
function DecodificaArrayOfConst(Info:TProgramInfo;const NomeParametro:string):TVarRecArray;
procedure DistruggiVarRec(var Valore:TVarRec);
function VariantToVarRec(Valore:variant):TVarRec;
function VarRecToVariant(Valore:TVarRec):variant;
function VarIsDateTime(Valore:variant):boolean;
function VarIsBoolean(Valore:variant):boolean;
function VarIsInt(Valore:variant):boolean;
function VarToBoolean(Value:variant):boolean;
procedure DestroyInternalObject(HandleOggetto:Int64);
procedure DestroyCostantObject(const Oggetto);
procedure DestroyObject(var Oggetto);
function GetFileExtension(const FileName:string):string;
function GetFileName(const FileName:string):string;
function MIMEFromFileExtension(Extension:string):string;
function SeNullo(const ValoreSottoTest,ValoreSostitutivo:variant):variant;
function GenerateID(IDLength:integer=16;IDNumericFlag:boolean=false):string;
procedure Async(AProcedure:TProc);
function ParseJSONObject(AString:string):TJSONobject;
function ReadJSONValue(AJSON:TJSONObject;const Name:string;DefaultValue:integer):integer;overload;
function ReadJSONValue(AJSON:TJSONObject;const Name:string;DefaultValue:boolean):boolean;overload;
function ReadJSONValue(AJSON:TJSONObject;const Name:string;DefaultValue:string):string;overload;

implementation

var StringIDCharacterSource:string;
    StringIDCharacterSourceLength:integer;

function ParseJSONObject(AString:string):TJSONobject;
begin
  Result:=TJSONObject.ParseJSONValue(AString,false,true) as TJSONObject;
end;

function ReadJSONValue(AJSON:TJSONObject;const Name:string;DefaultValue:integer):integer;
begin
  if (not(AJSON.TryGetValue<integer>(Name,Result))) then
    Result:=DefaultValue;
end;

function ReadJSONValue(AJSON:TJSONObject;const Name:string;DefaultValue:boolean):boolean;
begin
  if (not(AJSON.TryGetValue<boolean>(Name,Result))) then
    Result:=DefaultValue;
end;

function ReadJSONValue(AJSON:TJSONObject;const Name:string;DefaultValue:string):string;
begin
  if (not(AJSON.TryGetValue<string>(Name,Result))) then
    Result:=DefaultValue;
end;

procedure RaiseException(const AMessage:string);
begin
  raise Exception.Create(AMessage);
end;

procedure RaiseException(const AMessage:string;const Args:array of const);
begin
  raise Exception.CreateFmt(AMessage,Args);
end;

function AnsiPosEx(SottoStringa,Stringa:string;Posizione:integer):integer;
var I,MaxIndex,SubLen:integer;
begin
  Result:=0;
  SubLen:=Length(SottoStringa);
  if ((SubLen=0) or (Length(Stringa)=0) or (SubLen>Length(Stringa))) then
    Exit;
  MaxIndex:=Length(Stringa)-SubLen+1;
  for I:=Posizione to MaxIndex do
    if (AnsiCompareText(Copy(Stringa,I,SubLen),SottoStringa)=0) then
      begin
        Result:=I;
        Exit;
      end;
end;

procedure DestroyObject(var Oggetto);
begin
  if (Assigned(TObject(Oggetto))) then
    try
      TObject(Oggetto).Free;
    except
    end;
  TObject(Oggetto):=nil;
end;

procedure DestroyCostantObject(const Oggetto);
begin
  if (Assigned(TObject(Oggetto))) then
    try
      TObject(Oggetto).Free;
    except
    end;
end;

procedure DestroyInternalObject(HandleOggetto:Int64);
begin
  DestroyCostantObject(TObject(HandleOggetto));
end;

function SeNullo(const ValoreSottoTest,ValoreSostitutivo:variant):variant;
begin
  if (VarIsNull(ValoreSottoTest)) then
    Result:=ValoreSostitutivo
  else
    Result:=ValoreSottoTest;
end;

function VarIsInt(Valore:variant):boolean;
begin
  Result:=
    (VarType(Valore) in [varSmallint,varInteger,varShortInt,varByte,varWord,varLongWord,varInt64]);
end;

function VarIsBoolean(Valore:variant):boolean;
begin
  Result:=(VarType(Valore)=varBoolean);
end;

function VarIsDateTime(Valore:variant):boolean;
begin
  Result:=(VarType(Valore)=varDate);
end;

function VarToBoolean(Value:variant):boolean;
var StringValue:string;
begin
  StringValue:=VarToStrDef(Value,'?');
  Result:=StrToBoolDef(StringValue,false);
end;

function VarRecToVariant(Valore:TVarRec):variant;
begin
  case Valore.VType of
    vtInteger:
      Result:=Valore.VInteger;
    vtBoolean:
      Result:=Valore.VBoolean;
    vtChar:
      Result:=Valore.VChar;
    vtExtended:
      Result:=Valore.VExtended^;
    vtString:
      Result:=Valore.VString^;
    vtPointer:
      Result:=NativeInt(Valore.VPointer);
    vtPChar:
      Result:=StrPas(Valore.VPChar);
    vtAnsiString:
      Result:=String(Valore.VAnsiString);
    vtCurrency:
      Result:=Valore.VCurrency^;
    vtVariant:
      Result:=Valore.VVariant^;
    vtInt64:
      Result:=Valore.VInt64^;
    vtUnicodeString:
      Result:=string(PChar(Valore.VUnicodeString));
  else
    Result:=null;
  end;
end;

function VariantToVarRec(Valore:variant):TVarRec;
begin
  case VarType(Valore) of
    varInteger,varSmallint,varShortInt,varByte,varWord,varLongWord:
      begin
        Result.VType:=vtInteger;
        Result.VInteger:=Valore;
      end;
    varNull,varUnknown,varEmpty:
      begin
        Result.VType:=vtInteger;
        Result.VInteger:=0;
      end;
    varBoolean:
      begin
        Result.VType:=vtBoolean;
        Result.VBoolean:=Valore;
      end;
    varDouble,varSingle:
      begin
        Result.VType:=vtExtended;
        New(Result.VExtended);
        Result.VExtended^:=Valore;
      end;
    varString:
      begin
        Result.VType:=vtString;
        New(Result.VString);
        Result.VString^:=ShortString(Valore);
      end;
    varCurrency:
      begin
        Result.VType:=vtCurrency;
        New(Result.VCurrency);
        Result.VCurrency^:=Valore;
      end;
    varVariant:
      begin
        Result.VType:=vtVariant;
        New(Result.VVariant);
        Result.VVariant^:=Valore;
      end;
    varOleStr:
      begin
        Result.VType:=vtWideString;
        Result.VWideString:=nil;
        WideString(Result.VWideString):=WideString(Valore);
      end;
    varInt64:
      begin
        Result.VType:=vtInt64;
        New(Result.VInt64);
        Result.VInt64^:=Valore;
      end;
    varUString:
      begin
        Result.VType:=vtUnicodeString;
        Result.VUnicodeString:=nil;
        UnicodeString(Result.VUnicodeString):=UnicodeString(Valore);
      end;
  end;
end;

procedure DistruggiVarRec(var Valore:TVarRec);
begin
  case Valore.VType of
    vtExtended:
      Dispose(Valore.VExtended);
    vtString:
      Dispose(Valore.VString);
    vtCurrency:
      Dispose(Valore.VCurrency);
    vtVariant:
      Dispose(Valore.VVariant);
    vtWideString:
      WideString(Valore.VWideString):=WideString('');
    vtInt64:
      Dispose(Valore.VInt64);
    vtUnicodeString:
      UnicodeString(Valore.VUnicodeString):=UnicodeString('');
  end;
  Finalize(Valore);
end;

function DecodificaArrayOfConst(Info:TProgramInfo;const NomeParametro:string):TVarRecArray;
var k:integer;
    InfoArgs:IInfo;
begin
  try
    try
      InfoArgs:=Info.Vars[NomeParametro];
      SetLength(Result,InfoArgs.Member['length'].ValueAsInteger);
      for k:=0 to High(Result) do
        Result[k]:=VariantToVarRec(InfoArgs.Element(k).Value);
    finally
      InfoArgs:=nil;
    end;
  except
    Finalize(Result);
  end;
end;

function GetFileExtension(const FileName:string):string;
begin
  Result:=Trim(ExtractFileExt(FileName));
  if (Result<>'') then
    if (Result[1]='.') then
      Delete(Result,1,1);
end;

function GetFileName(const FileName:string):string;
var
  Position:integer;
begin
  Result:=ExtractFileName(FileName);
  Position:=LastDelimiter('.',Result);
  if (Position>0) then
    Result:=Copy(Result,1,Position-1);
end;

function MIMEFromFileExtension(Extension:string):string;
begin
  Extension:=LowerCase(Extension);
  if (Extension='323') then
    Result:='text/h323'
  else if (Extension='acx') then
    Result:='application/internet-property-stream'
  else if (Extension='ai') then
    Result:='application/postscript'
  else if (Extension='aif') then
    Result:='audio/x-aiff'
  else if (Extension='aifc') then
    Result:='audio/x-aiff'
  else if (Extension='aiff') then
    Result:='audio/x-aiff'
  else if (Extension='asf') then
    Result:='video/x-ms-asf'
  else if (Extension='asr') then
    Result:='video/x-ms-asf'
  else if (Extension='asx') then
    Result:='video/x-ms-asf'
  else if (Extension='au') then
    Result:='audio/basic'
  else if (Extension='avi') then
    Result:='video/x-msvideo'
  else if (Extension='axs') then
    Result:='application/olescript'
  else if (Extension='bas') then
    Result:='text/plain'
  else if (Extension='bcpio') then
    Result:='application/x-bcpio'
  else if (Extension='bin') then
    Result:='application/octet-stream'
  else if (Extension='bmp') then
    Result:='image/bmp'
  else if (Extension='c') then
    Result:='text/plain'
  else if (Extension='cat') then
    Result:='application/vnd.ms-pkiseccat'
  else if (Extension='cdf') then
    Result:='application/x-cdf'
  else if (Extension='cdf') then
    Result:='application/x-netcdf'
  else if (Extension='cer') then
    Result:='application/x-x509-ca-cert'
  else if (Extension='class') then
    Result:='application/octet-stream'
  else if (Extension='clp') then
    Result:='application/x-msclip'
  else if (Extension='cmx') then
    Result:='image/x-cmx'
  else if (Extension='cod') then
    Result:='image/cis-cod'
  else if (Extension='cpio') then
    Result:='application/x-cpio'
  else if (Extension='crd') then
    Result:='application/x-mscardfile'
  else if (Extension='crl') then
    Result:='application/pkix-crl'
  else if (Extension='crt') then
    Result:='application/x-x509-ca-cert'
  else if (Extension='csh')then
    Result:='application/x-csh'
  else if (Extension='css') then
    Result:='text/css'
  else if (Extension='dcr') then
    Result:='application/x-director'
  else if (Extension='der') then
    Result:='application/x-x509-ca-cert'
  else if (Extension='dir') then
    Result:='application/x-director'
  else if (Extension='dll') then
    Result:='application/x-msdownload'
  else if (Extension='dms') then
    Result:='application/octet-stream'
  else if (Extension='doc') then
    Result:='application/msword'
  else if (Extension='dot') then
    Result:='application/msword'
  else if (Extension='dvi') then
    Result:='application/x-dvi'
  else if (Extension='dxr') then
    Result:='application/x-director'
  else if (Extension='eps') then
    Result:='application/postscript'
  else if (Extension='etx') then
    Result:='text/x-setext'
  else if (Extension='evy') then
    Result:='application/envoy'
  else if (Extension='exe') then
    Result:='application/octet-stream'
  else if (Extension='fif') then
    Result:='application/fractals'
  else if (Extension='flr') then
    Result:='x-world/x-vrml'
  else if (Extension='gif') then
    Result:='image/gif'
  else if (Extension='gtar') then
    Result:='application/x-gtar'
  else if (Extension='gz') then
    Result:='application/x-gzip'
  else if (Extension='h') then
    Result:='text/plain'
  else if (Extension='hdf') then
    Result:='application/x-hdf'
  else if (Extension='hlp') then
    Result:='application/winhlp'
  else if (Extension='hqx') then
    Result:='application/mac-binhex40'
  else if (Extension='hta') then
    Result:='application/hta'
  else if (Extension='htc') then
    Result:='text/x-component'
  else if (Extension='htm') then
    Result:='text/html'
  else if (Extension='html') then
    Result:='text/html'
  else if (Extension='htt') then
    Result:='text/webviewhtml'
  else if (Extension='ico') then
    Result:='image/x-icon'
  else if (Extension='ief') then
    Result:='image/ief'
  else if (Extension='iii') then
    Result:='application/x-iphone'
  else if (Extension='ins') then
    Result:='application/x-internet-signup'
  else if (Extension='isp') then
    Result:='application/x-internet-signup'
  else if (Extension='jfif') then
    Result:='image/pipeg'
  else if (Extension='jpe') then
    Result:='image/jpeg'
  else if (Extension='jpeg') then
    Result:='image/jpeg'
  else if (Extension='jpg') then
    Result:='image/jpeg'
  else if (Extension='js') then
    Result:='application/x-javascript'
  else if (Extension='latex') then
    Result:='application/x-latex'
  else if (Extension='lha') then
    Result:='application/octet-stream'
  else if (Extension='lsf') then
    Result:='video/x-la-asf'
  else if (Extension='lsx') then
    Result:='video/x-la-asf'
  else if (Extension='lzh') then
    Result:='application/octet-stream'
  else if (Extension='m13') then
    Result:='application/x-msmediaview'
  else if (Extension='m14') then
    Result:='application/x-msmediaview'
  else if (Extension='m3u') then
    Result:='audio/x-mpegurl'
  else if (Extension='man') then
    Result:='application/x-troff-man'
  else if (Extension='mdb') then
    Result:='application/x-msaccess'
  else if (Extension='me') then
    Result:='application/x-troff-me'
  else if (Extension='mht') then
    Result:='message/rfc822'
  else if (Extension='mhtml') then
    Result:='message/rfc822'
  else if (Extension='mid') then
    Result:='audio/mid'
  else if (Extension='mny') then
    Result:='application/x-msmoney'
  else if (Extension='mov') then
    Result:='video/quicktime'
  else if (Extension='movie') then
    Result:='video/x-sgi-movie'
  else if (Extension='mp2') then
    Result:='video/mpeg'
  else if (Extension='mp3') then
    Result:='audio/mpeg'
  else if (Extension='mpa') then
    Result:='video/mpeg'
  else if (Extension='mpe') then
    Result:='video/mpeg'
  else if (Extension='mpeg') then
    Result:='video/mpeg'
  else if (Extension='mpg') then
    Result:='video/mpeg'
  else if (Extension='mpp') then
    Result:='application/vnd.ms-project'
  else if (Extension='mpv2') then
    Result:='video/mpeg'
  else if (Extension='ms') then
    Result:='application/x-troff-ms'
  else if (Extension='msg') then
    Result:='application/vnd.ms-outlook'
  else if (Extension='mvb') then
    Result:='application/x-msmediaview'
  else if (Extension='nc') then
    Result:='application/x-netcdf'
  else if (Extension='nws') then
    Result:='message/rfc822'
  else if (Extension='oda') then
    Result:='application/oda'
  else if (Extension='p10') then
    Result:='application/pkcs10'
  else if (Extension='p12') then
    Result:='application/x-pkcs12'
  else if (Extension='p7b') then
    Result:='application/x-pkcs7-certificates'
  else if (Extension='p7c') then
    Result:='application/x-pkcs7-mime'
  else if (Extension='p7m') then
    Result:='application/x-pkcs7-mime'
  else if (Extension='p7r') then
    Result:='application/x-pkcs7-certreqresp'
  else if (Extension='p7s') then
    Result:='application/x-pkcs7-signature'
  else if (Extension='pbm') then
    Result:='image/x-HTTPPortble-bitmap'
  else if (Extension='pdf') then
    Result:='application/pdf'
  else if (Extension='pfx') then
    Result:='application/x-pkcs12'
  else if (Extension='pgm') then
    Result:='image/x-HTTPPortble-graymap'
  else if (Extension='pko') then
    Result:='application/ynd.ms-pkipko'
  else if (Extension='pma') then
    Result:='application/x-perfmon'
  else if (Extension='pmc') then
    Result:='application/x-perfmon'
  else if (Extension='pml') then
    Result:='application/x-perfmon'
  else if (Extension='pmr') then
    Result:='application/x-perfmon'
  else if (Extension='pmw') then
    Result:='application/x-perfmon'
  else if (Extension='pnm') then
    Result:='image/x-HTTPPortble-anymap'
  else if (Extension='pot') then
    Result:='application/vnd.ms-powerpoint'
  else if (Extension='ppm') then
    Result:='image/x-HTTPPortble-pixmap'
  else if (Extension='pps') then
    Result:='application/vnd.ms-powerpoint'
  else if (Extension='ppt') then
    Result:='application/vnd.ms-powerpoint'
  else if (Extension='prf') then
    Result:='application/pics-rules'
  else if (Extension='ps') then
    Result:='application/postscript'
  else if (Extension='pub') then
    Result:='application/x-mspublisher'
  else if (Extension='qt') then
    Result:='video/quicktime'
  else if (Extension='ra') then
    Result:='audio/x-pn-realaudio'
  else if (Extension='ram') then
    Result:='audio/x-pn-realaudio'
  else if (Extension='ras') then
    Result:='image/x-cmu-raster'
  else if (Extension='rgb') then
    Result:='image/x-rgb'
  else if (Extension='rmi') then
    Result:='audio/mid'
  else if (Extension='roff') then
    Result:='application/x-troff'
  else if (Extension='rtf') then
    Result:='application/rtf'
  else if (Extension='rtx') then
    Result:='text/richtext'
  else if (Extension='scd') then
    Result:='application/x-msschedule'
  else if (Extension='sct') then
    Result:='text/scriptlet'
  else if (Extension='setpay') then
    Result:='application/set-payment-initiation'
  else if (Extension='setreg') then
    Result:='application/set-registration-initiation'
  else if (Extension='sh') then
    Result:='application/x-sh'
  else if (Extension='shar') then
    Result:='application/x-shar'
  else if (Extension='sit') then
    Result:='application/x-stuffit'
  else if (Extension='snd') then
    Result:='audio/basic'
  else if (Extension='spc') then
    Result:='application/x-pkcs7-certificates'
  else if (Extension='spl') then
    Result:='application/futuresplash'
  else if (Extension='src') then
    Result:='application/x-wais-source'
  else if (Extension='sst') then
    Result:='application/vnd.ms-pkicertstore'
  else if (Extension='stl') then
    Result:='application/vnd.ms-pkistl'
  else if (Extension='stm') then
    Result:='text/html'
  else if (Extension='sv4cpio') then
    Result:='application/x-sv4cpio'
  else if (Extension='sv4crc') then
    Result:='application/x-sv4crc'
  else if (Extension='svg') then
    Result:='image/svg+xml'
  else if (Extension='swf') then
    Result:='application/x-shockwave-flash'
  else if (Extension='t') then
    Result:='application/x-troff'
  else if (Extension='tar') then
    Result:='application/x-tar'
  else if (Extension='tcl') then
    Result:='application/x-tcl'
  else if (Extension='tex') then
    Result:='application/x-tex'
  else if (Extension='texi') then
    Result:='application/x-texinfo'
  else if (Extension='texinfo') then
    Result:='application/x-texinfo'
  else if (Extension='tgz') then
    Result:='application/x-compressed'
  else if (Extension='tif') then
    Result:='image/tiff'
  else if (Extension='tiff') then
    Result:='image/tiff'
  else if (Extension='tr') then
    Result:='application/x-troff'
  else if (Extension='trm') then
    Result:='application/x-msterminal'
  else if (Extension='tsv') then
    Result:='text/tab-separated-values'
  else if (Extension='txt') then
    Result:='text/plain'
  else if (Extension='uls') then
    Result:='text/iuls'
  else if (Extension='ustar') then
    Result:='application/x-ustar'
  else if (Extension='vcf') then
    Result:='text/x-vcard'
  else if (Extension='vrml') then
    Result:='x-world/x-vrml'
  else if (Extension='wav') then
    Result:='audio/x-wav'
  else if (Extension='wcm') then
    Result:='application/vnd.ms-works'
  else if (Extension='wdb') then
    Result:='application/vnd.ms-works'
  else if (Extension='wks') then
    Result:='application/vnd.ms-works'
  else if (Extension='wmf') then
    Result:='application/x-msmetafile'
  else if (Extension='wps') then
    Result:='application/vnd.ms-works'
  else if (Extension='wri') then
    Result:='application/x-mswrite'
  else if (Extension='wrl') then
    Result:='x-world/x-vrml'
  else if (Extension='wrz') then
    Result:='x-world/x-vrml'
  else if (Extension='xaf') then
    Result:='x-world/x-vrml'
  else if (Extension='xbm') then
    Result:='image/x-xbitmap'
  else if (Extension='xla') then
    Result:='application/vnd.ms-excel'
  else if (Extension='xlc') then
    Result:='application/vnd.ms-excel'
  else if (Extension='xlm') then
    Result:='application/vnd.ms-excel'
  else if (Extension='xls') then
    Result:='application/vnd.ms-excel'
  else if (Extension='xlt') then
    Result:='application/vnd.ms-excel'
  else if (Extension='xlw') then
    Result:='application/vnd.ms-excel'
  else if (Extension='xof') then
    Result:='x-world/x-vrml'
  else if (Extension='xpm') then
    Result:='image/x-xpixmap'
  else if (Extension='xwd') then
    Result:='image/x-xwindowdump'
  else if (Extension='z') then
    Result:='application/x-compress'
  else if (Extension='zip') then
    Result:='application/zip'
  else
    Result:='application/octet-stream';
end;

function GenerateID(IDLength:integer;IDNumericFlag:boolean):string;
var k,Module,Position,Dice:integer;
begin
  Result:='';
  Module:=StringIDCharacterSourceLength*Trunc(1E6);
  for k:=1 to IDLength do
    begin
      Dice:=Random(Module);
      if (IDNumericFlag) then
        Position:=Dice mod 10
      else
        Position:=Dice mod StringIDCharacterSourceLength;
      Result:=Result+StringIDCharacterSource[Position+1];
    end;
end;

procedure Async(AProcedure:TProc);
begin
  TThread.CreateAnonymousThread(AProcedure).Start;
end;

initialization
  StringIDCharacterSource:=
    '0123456789'+
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'+
    'abcdefghijklmnopqrstuvwxyz';
  StringIDCharacterSourceLength:=Length(StringIDCharacterSource);
  Randomize;

end.
