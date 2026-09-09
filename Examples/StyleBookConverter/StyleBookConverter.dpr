program StyleBookConverter;

{$APPTYPE CONSOLE}

{
  One-shot converter: rewrites FireMonkey .fmx / .dfm files so every
  TStyleBook component (with its hex-encoded ResourcesBin blocks) is
  replaced with a TZxStyleBook whose styles are stored as text.

  Usage:
    StyleBookConverter.exe [--dry-run] <file-or-glob> [<file-or-glob> ...]

  Examples:
    StyleBookConverter.exe Z:\NEXTORE.App\Core\source\NXT.App.Styles.dfm
    StyleBookConverter.exe --dry-run "C:\Work\DriveZ\Synthetic.Application\**\*.fmx"

  The converter relies only on FMX's public API:
    - TStyleStreaming.LoadFromStream  (auto-detects binary/text)
    - TStyleStreaming.SaveToStream(..., TStyleFormat.Text)

  Binary style data is decoded, then re-emitted as a DFM-quoted string-list
  StyleText property compatible with TZxStyleCollectionItem.
}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.Types,
  System.Skia,
  FMX.Skia,
  FMX.Types,
  FMX.Controls,
  FMX.Styles,
  FMX.Effects,
  FMX.Filter.Effects,
  FMX.Ani,
  FMX.ActnList,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Objects,
  FMX.Layouts,
  FMX.ListBox,
  FMX.TabControl,
  FMX.ComboEdit,
  FMX.Memo,
  FMX.Grid,
  FMX.DateTimeCtrls,
  FMX.Colors,
  FMX.TreeView,
  FMX.Calendar,
  FMX.Menus,
  Zx.Ani,
  Zx.AnimatedImageSourceList,
  Zx.Buttons,
  Zx.Styles.Objects,
  Zx.SvgBrushList,
  Zx.Text;

type
  TConversionStats = record
    FilesScanned: Integer;
    FilesChanged: Integer;
    StyleBooksConverted: Integer;
    ItemsConverted: Integer;
  end;

var
  GStats: TConversionStats;
  GDryRun: Boolean = False;

function HexToBytes(const AHex: string): TBytes;
var
  Clean: string;
  I, J: Integer;
begin
  SetLength(Clean, Length(AHex));
  J := 0;
  for I := 1 to Length(AHex) do
    if CharInSet(AHex[I], ['0' .. '9', 'A' .. 'F', 'a' .. 'f']) then
    begin
      Inc(J);
      Clean[J] := AHex[I];
    end;
  SetLength(Clean, J);
  if Odd(Length(Clean)) then
    raise Exception.Create('Odd hex digit count in ResourcesBin block');
  SetLength(Result, Length(Clean) div 2);
  for I := 0 to High(Result) do
    Result[I] := StrToInt('$' + Copy(Clean, I * 2 + 1, 2));
end;

function DecodeResourcesBinToText(const AHex: string): string;
var
  InStream: TBytesStream;
  OutStream: TStringStream;
  Style: TFmxObject;
begin
  InStream := TBytesStream.Create(HexToBytes(AHex));
  try
    InStream.Position := 0;
    if not TStyleStreaming.CanLoadFromStream(InStream) then
      raise Exception.Create('TStyleStreaming.CanLoadFromStream rejected the decoded block');
    InStream.Position := 0;
    Style := TStyleStreaming.LoadFromStream(InStream);
    try
      OutStream := TStringStream.Create('', TEncoding.UTF8);
      try
        TStyleStreaming.SaveToStream(Style, OutStream, TStyleFormat.Text);
        Result := OutStream.DataString;
      finally
        OutStream.Free;
      end;
    finally
      Style.Free;
    end;
  finally
    InStream.Free;
  end;
end;

function QuoteDFMString(const S: string): string;
begin
  Result := '''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

function FormatStyleTextProperty(const Indent, LinesText: string): string;
var
  Lines: TStringList;
  I: Integer;
  SB: TStringBuilder;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := LinesText;
    while (Lines.Count > 0) and (Lines[Lines.Count - 1] = '') do
      Lines.Delete(Lines.Count - 1);
    SB := TStringBuilder.Create;
    try
      SB.Append(Indent).Append('StyleText = (').AppendLine;
      for I := 0 to Lines.Count - 1 do
      begin
        SB.Append(Indent).Append('  ').Append(QuoteDFMString(Lines[I]));
        if I = Lines.Count - 1 then
          SB.Append(')');
        SB.AppendLine;
      end;
      Result := SB.ToString;
    finally
      SB.Free;
    end;
  finally
    Lines.Free;
  end;
end;

function ReplaceResourcesBin(const ASource: string): string;
const
  Marker = 'ResourcesBin';
var
  I, LineStart, Indent, BraceOpen, BraceClose, HexStart: Integer;
  Hex, Replacement, IndentStr: string;
  Converted: Boolean;
begin
  Result := ASource;
  I := 1;
  repeat
    I := PosEx(Marker, Result, I);
    if I = 0 then
      Break;

    LineStart := I;
    while (LineStart > 1) and not CharInSet(Result[LineStart - 1], [#10, #13]) do
      Dec(LineStart);
    Indent := I - LineStart;
    IndentStr := Copy(Result, LineStart, Indent);

    BraceOpen := PosEx('{', Result, I + Length(Marker));
    if BraceOpen = 0 then
      Break;
    BraceClose := PosEx('}', Result, BraceOpen + 1);
    if BraceClose = 0 then
      Break;

    HexStart := BraceOpen + 1;
    Hex := Copy(Result, HexStart, BraceClose - HexStart);

    Converted := False;
    try
      Replacement := FormatStyleTextProperty(IndentStr,
        DecodeResourcesBinToText(Hex));
      Converted := True;
    except
      on E: Exception do
        Writeln(ErrOutput, Format('  [WARN] Failed to decode ResourcesBin block at offset %d: %s',
          [I, E.Message]));
    end;

    if Converted then
    begin
      while (BraceClose < Length(Result)) and
        CharInSet(Result[BraceClose + 1], [#13, #10]) do
        Inc(BraceClose);

      Delete(Result, LineStart, BraceClose - LineStart + 1);
      Insert(Replacement, Result, LineStart);

      I := LineStart + Length(Replacement);
      Inc(GStats.ItemsConverted);
    end
    else
      I := BraceClose + 1;
  until False;
end;

function ReplaceClassNames(const ASource: string; out ACount: Integer): string;
var
  I: Integer;
  Prev: Char;
begin
  Result := ASource;
  ACount := 0;
  I := 1;
  repeat
    I := PosEx(': TStyleBook', Result, I);
    if I = 0 then
      Break;
    if I + Length(': TStyleBook') <= Length(Result) then
    begin
      Prev := Result[I + Length(': TStyleBook')];
      if CharInSet(Prev, ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_']) then
      begin
        Inc(I);
        Continue;
      end;
    end;
    Delete(Result, I, Length(': TStyleBook'));
    Insert(': TZxStyleBook', Result, I);
    Inc(I, Length(': TZxStyleBook'));
    Inc(ACount);
  until False;
end;

procedure ConvertFile(const APath: string);
var
  Original, Updated: string;
  ClassCount: Integer;
  Encoding: TEncoding;
  Bytes: TBytes;
  PreambleSize, ItemsBefore: Integer;
begin
  Inc(GStats.FilesScanned);
  Writeln(Format('Scanning %s', [APath]));

  Bytes := TFile.ReadAllBytes(APath);
  Encoding := nil;
  PreambleSize := TEncoding.GetBufferEncoding(Bytes, Encoding, TEncoding.UTF8);
  Original := Encoding.GetString(Bytes, PreambleSize,
    Length(Bytes) - PreambleSize);

  if Pos('TStyleBook', Original) = 0 then
  begin
    Writeln('  (no TStyleBook references; skipping)');
    Exit;
  end;

  ItemsBefore := GStats.ItemsConverted;
  Updated := ReplaceResourcesBin(Original);
  Updated := ReplaceClassNames(Updated, ClassCount);

  if Updated = Original then
  begin
    Writeln('  (no changes needed)');
    Exit;
  end;

  Inc(GStats.FilesChanged);
  Inc(GStats.StyleBooksConverted, ClassCount);
  Writeln(Format('  -> %d class rename(s), %d ResourcesBin block(s) converted',
    [ClassCount, GStats.ItemsConverted - ItemsBefore]));

  if GDryRun then
  begin
    Writeln('  (dry-run: not writing)');
    Exit;
  end;

  TFile.WriteAllText(APath, Updated, Encoding);
  Writeln('  written.');
end;

procedure ExpandAndConvert(const APattern: string);
var
  Dir, Mask: string;
  Files: TStringDynArray;
  F: string;
begin
  if TFile.Exists(APattern) then
  begin
    ConvertFile(APattern);
    Exit;
  end;

  Dir := ExtractFilePath(APattern);
  Mask := ExtractFileName(APattern);
  if Dir = '' then
    Dir := GetCurrentDir;
  if not TDirectory.Exists(Dir) then
  begin
    Writeln(ErrOutput, 'Directory not found: ', Dir);
    Exit;
  end;
  Files := TDirectory.GetFiles(Dir, Mask, TSearchOption.soAllDirectories);
  if Length(Files) = 0 then
    Writeln(ErrOutput, 'No files matched: ', APattern);
  for F in Files do
    ConvertFile(F);
end;

procedure PrintUsage;
begin
  Writeln('StyleBookConverter: rewrites FMX TStyleBook DFM blocks as text TZxStyleBook.');
  Writeln;
  Writeln('Usage:');
  Writeln('  StyleBookConverter.exe [--dry-run] <file-or-glob> [<file-or-glob> ...]');
  Writeln;
  Writeln('Examples:');
  Writeln('  StyleBookConverter.exe NXT.App.Styles.dfm');
  Writeln('  StyleBookConverter.exe --dry-run "C:\Work\repo\*.fmx"');
end;

var
  I: Integer;
  Arg: string;
  HadTarget: Boolean;
begin
  try
    if ParamCount = 0 then
    begin
      PrintUsage;
      Halt(1);
    end;

    HadTarget := False;
    for I := 1 to ParamCount do
    begin
      Arg := ParamStr(I);
      if SameText(Arg, '--dry-run') or SameText(Arg, '-n') then
        GDryRun := True
      else if SameText(Arg, '--help') or SameText(Arg, '-h') then
      begin
        PrintUsage;
        Halt(0);
      end
      else
      begin
        ExpandAndConvert(Arg);
        HadTarget := True;
      end;
    end;

    if not HadTarget then
    begin
      PrintUsage;
      Halt(1);
    end;

    Writeln;
    Writeln(Format('Done. Scanned %d file(s), changed %d, renamed %d class reference(s), converted %d item(s).',
      [GStats.FilesScanned, GStats.FilesChanged, GStats.StyleBooksConverted, GStats.ItemsConverted]));
    if GDryRun then
      Writeln('(dry-run — no files were written)');
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.
