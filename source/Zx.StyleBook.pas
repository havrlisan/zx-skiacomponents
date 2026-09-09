{ ************************************************************************** }
{ *                                                                        * }
{ *                           Zx-SkiaComponents                            * }
{ *                                                                        * }
{ *           Copyright (c) 2025 Zx-SkiaComponents Project.                * }
{ *                                                                        * }
{ * Use of this source code is governed by the MIT license that can be     * }
{ * found in the LICENSE file.                                             * }
{ *                                                                        * }
{ ************************************************************************** }
unit Zx.StyleBook;

{
  TZxStyleBook is a sibling of FMX TStyleBook that serializes its styles as
  readable text DFM instead of the base class's hex-encoded binary block.

  Why a sibling (not a TStyleBook descendant):
    FMX TStyleCollectionItem.DefineProperties uses DefineBinaryProperty and
    its supporting methods (StyleStored, GetIsEmpty, ReadResources,
    WriteResources) are private + non-virtual. The inherited binary property
    cannot be suppressed from a descendant, so a subclass would produce both
    the new text form AND the old hex in every .dfm. Re-implementing the
    collection/item surface directly on TFmxObject / TCollectionItem side-
    steps that.

  Why text-in-a-TStrings property (not nested DFM components):
    The obvious alternative is to expose each style object tree as real DFM
    children of the style book (object TStyleContainer ... object TLayout
    ... end ... end). The DFM is then beautifully native, with no quoting
    or escape artefacts. The deal-breaker is that Delphi's form designer
    eagerly instantiates every nested component at form-load time -- there
    is no lazy-subcomponent facility. For a non-trivial style book (hundreds
    of TLayout / TText / TBrushObject children) opening the form in the IDE
    becomes seconds-slow, and the cost scales with style volume.

    FMX's own TStyleBook sidesteps this by storing the tree as an opaque
    binary blob (ResourcesBin) and deferring decode until first Style
    access. We keep the same lazy-load shape by storing the text-DFM as a
    TStrings-style property (StyleText) on each platform item. It parses
    as a flat list of strings at form-load (cheap) and the actual style
    components are built only when TZxStyleManager / TStyleManager reach
    for them. The visual cost is that each style-line appears as an
    individually quoted DFM entry with #39 escapes for single quotes -- a
    one-time aesthetic annoyance traded against design-time responsiveness
    that scales with style-book size.

    TStyleStreaming.LoadFromStream auto-detects text vs binary signatures
    on read, so no custom reader is needed; the text we emit via
    TStyleFormat.Text round-trips through the same FMX loader.
}

interface

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  System.Messaging,
  System.Generics.Collections,
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  FMX.Types,
  FMX.Controls,
  FMX.Styles,
  FMX.BehaviorManager;

type
  { Resolves a TZxStyleBook.StyleFile (relative) to an absolute path at design-
    time. Installed by Zx.Designtime using ToolsAPI to anchor against the form
    file currently being edited. nil at runtime / when design package is not
    loaded. }
  TZxStyleBookResolver = function(const ABook: TComponent;
    const ARelativePath: string): string;

var
  ZxStyleBookDesignTimeResolver: TZxStyleBookResolver;

type
  TZxStyleBook = class;

  TZxStyleCollectionItem = class(TCollectionItem)
  private
    [Weak] FStyleBook: TZxStyleBook;
    FStyle: TFmxObject;
    FPlatform: string;
    FUnsupportedPlatform: Boolean;
    procedure SetPlatform(const Value: string);
    function GetStyle: TFmxObject;
    function HasStyleText: Boolean;
    procedure ReadStyleText(Reader: TReader);
    procedure WriteStyleText(Writer: TWriter);
    function GetIsEmpty: Boolean;
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear;
    procedure LoadFromStream(const Stream: TStream);
    procedure SaveToStream(const Stream: TStream;
      const Format: TStyleFormat = TStyleFormat.Text);
    property IsEmpty: Boolean read GetIsEmpty;
    property Style: TFmxObject read GetStyle;
    property StyleBook: TZxStyleBook read FStyleBook;
    property UnsupportedPlatform: Boolean read FUnsupportedPlatform;
  published
    property Platform: string read FPlatform write SetPlatform;
  end;

  TZxStyleCollection = class(TOwnedCollection)
  private
    [Weak] FStyleBook: TZxStyleBook;
    function GetItem(Index: Integer): TZxStyleCollectionItem;
    procedure SetItem(Index: Integer; const Value: TZxStyleCollectionItem);
  protected
    procedure Notify(Item: TCollectionItem;
      Action: TCollectionNotification); override;
  public
    constructor Create(AOwner: TZxStyleBook);
    function Add: TZxStyleCollectionItem;
    property Items[Index: Integer]: TZxStyleCollectionItem
      read GetItem write SetItem; default;
    property StyleBook: TZxStyleBook read FStyleBook;
  end;

  TZxStyleBook = class(TFmxObject)
  private
    FStyles: TZxStyleCollection;
    FStylesDic: TDictionary<string, TZxStyleCollectionItem>;
    FCurrentItemIndex: Integer;
    FUseStyleManager: Boolean;
    FStyleFile: string;
    FBeforeStyleChangingId: Integer;
    FStyleChangedId: Integer;
    procedure SetStyles(const Value: TZxStyleCollection);
    procedure SetUseStyleManager(const Value: Boolean);
    procedure SetStyleFile(const Value: string);
    function GetCurrentItem: TZxStyleCollectionItem;
    function GetStyle: TFmxObject; overload;
    function CustomFindStyleResource(const AStyleLookup: string;
      const Clone: Boolean): TFmxObject;
    procedure BeforeStyleChangingHandler(const Sender: TObject;
      const Msg: TMessage);
    procedure StyleChangedHandler(const Sender: TObject;
      const Msg: TMessage);
    function TryOpenStyleStream: TStream;
  protected
    procedure ChooseStyleIndex; virtual;
    procedure Loaded; override;
    procedure RebuildDictionary;
    function StyleIndexByContext(const Context: TFmxObject): Integer;
    procedure CollectionChanged;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function GetStyle(const Context: TFmxObject): TFmxObject; overload;
    function GetStyleContainer: TStyleContainer;
    procedure LoadFromStream(const Stream: TStream);
    procedure LoadStyleFromFile;
    property CurrentItem: TZxStyleCollectionItem read GetCurrentItem;
    property CurrentItemIndex: Integer read FCurrentItemIndex;
    property Style: TFmxObject read GetStyle;
  published
    { Path to an external .style file (text DFM produced by TStyleFormat.Text).
      When non-empty the inline StyleText DFM property is suppressed, and the
      style is sourced from:
        * at runtime: a linked resource named UpperCase(filename-without-ext)
          of type RT_RCDATA (MSWINDOWS); then a file relative to the EXE;
          then an absolute path.
        * at design-time: resolved via ZxStyleBookDesignTimeResolver (anchors
          against the .fmx being edited).
      Keep the path relative to the form file -- just like .pas/.fmx/.dfm,
      the .style file is expected to travel alongside its form. }
    property StyleFile: string read FStyleFile write SetStyleFile;
    property Styles: TZxStyleCollection read FStyles write SetStyles;
    property UseStyleManager: Boolean read FUseStyleManager
      write SetUseStyleManager default False;
  end;

implementation

{ TZxStyleCollectionItem }

constructor TZxStyleCollectionItem.Create(Collection: TCollection);
begin
  inherited;
  if Collection is TZxStyleCollection then
    FStyleBook := TZxStyleCollection(Collection).FStyleBook;
  FStyle := TStyleContainer.Create(nil);
end;

destructor TZxStyleCollectionItem.Destroy;
begin
  FreeAndNil(FStyle);
  inherited;
  if FStyleBook <> nil then
    FStyleBook.CollectionChanged;
end;

procedure TZxStyleCollectionItem.Assign(Source: TPersistent);
var
  Src: TZxStyleCollectionItem;
  Buf: TMemoryStream;
begin
  if Source is TZxStyleCollectionItem then
  begin
    Src := TZxStyleCollectionItem(Source);
    FPlatform := Src.FPlatform;
    FStyle.DeleteChildren;
    if Src.FStyle.ChildrenCount > 0 then
    begin
      Buf := TMemoryStream.Create;
      try
        TStyleStreaming.SaveToStream(Src.FStyle, Buf);
        Buf.Position := 0;
        LoadFromStream(Buf);
      finally
        Buf.Free;
      end;
    end;
    if FStyleBook <> nil then
      FStyleBook.CollectionChanged;
  end
  else
    inherited;
end;

procedure TZxStyleCollectionItem.Clear;
begin
  FStyle.DeleteChildren;
end;

procedure TZxStyleCollectionItem.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('StyleText', ReadStyleText, WriteStyleText, HasStyleText);
end;

function TZxStyleCollectionItem.GetDisplayName: string;
begin
  if FPlatform.IsEmpty then
    Result := inherited GetDisplayName
  else
    Result := FPlatform;
end;

function TZxStyleCollectionItem.GetIsEmpty: Boolean;
begin
  Result := (FStyle = nil) or (FStyle.ChildrenCount = 0);
end;

function TZxStyleCollectionItem.GetStyle: TFmxObject;
begin
  Result := FStyle;
end;

function TZxStyleCollectionItem.HasStyleText: Boolean;
begin
  if (FStyleBook <> nil) and (FStyleBook.FStyleFile <> '') then
    Exit(False);
  Result := not IsEmpty;
end;

procedure TZxStyleCollectionItem.LoadFromStream(const Stream: TStream);
begin
  if TStyleStreaming.CanLoadFromStream(Stream) then
  begin
    FreeAndNil(FStyle);
    FStyle := TStyleStreaming.LoadFromStream(Stream);
    TStyleManager.RemoveStyleFromGlobalPool(FStyle);
    FUnsupportedPlatform := False;
  end
  else
    FUnsupportedPlatform := True;
end;

procedure TZxStyleCollectionItem.ReadStyleText(Reader: TReader);
var
  Lines: TStringList;
  Text: string;
  TextStream: TStringStream;
begin
  Lines := TStringList.Create;
  try
    Reader.ReadListBegin;
    while not Reader.EndOfList do
      Lines.Add(Reader.ReadString);
    Reader.ReadListEnd;
    Text := Lines.Text;
  finally
    Lines.Free;
  end;
  if Text = '' then
    Exit;
  TextStream := TStringStream.Create(Text, TEncoding.UTF8);
  try
    TextStream.Position := 0;
    LoadFromStream(TextStream);
  finally
    TextStream.Free;
  end;
end;

procedure TZxStyleCollectionItem.SaveToStream(const Stream: TStream;
  const Format: TStyleFormat);
begin
  if FStyle <> nil then
    TStyleStreaming.SaveToStream(FStyle, Stream, Format);
end;

procedure TZxStyleCollectionItem.SetPlatform(const Value: string);
begin
  if FPlatform <> Value then
  begin
    FPlatform := Value;
    if FStyleBook <> nil then
      FStyleBook.CollectionChanged;
  end;
end;

procedure TZxStyleCollectionItem.WriteStyleText(Writer: TWriter);
var
  Buf: TStringStream;
  Lines: TStringList;
  I: Integer;
begin
  if IsEmpty then
  begin
    Writer.WriteListBegin;
    Writer.WriteListEnd;
    Exit;
  end;
  Buf := TStringStream.Create('', TEncoding.UTF8);
  try
    TStyleStreaming.SaveToStream(FStyle, Buf, TStyleFormat.Text);
    Lines := TStringList.Create;
    try
      Lines.Text := Buf.DataString;
      Writer.WriteListBegin;
      for I := 0 to Lines.Count - 1 do
        Writer.WriteString(Lines[I]);
      Writer.WriteListEnd;
    finally
      Lines.Free;
    end;
  finally
    Buf.Free;
  end;
end;

{ TZxStyleCollection }

constructor TZxStyleCollection.Create(AOwner: TZxStyleBook);
begin
  inherited Create(AOwner, TZxStyleCollectionItem);
  FStyleBook := AOwner;
end;

function TZxStyleCollection.Add: TZxStyleCollectionItem;
begin
  Result := TZxStyleCollectionItem(inherited Add);
end;

function TZxStyleCollection.GetItem(Index: Integer): TZxStyleCollectionItem;
begin
  Result := TZxStyleCollectionItem(inherited GetItem(Index));
end;

procedure TZxStyleCollection.Notify(Item: TCollectionItem;
  Action: TCollectionNotification);
begin
  inherited;
  if FStyleBook <> nil then
  begin
    FStyleBook.CollectionChanged;
    if (Action = TCollectionNotification.cnDeleting) and
      (FStyleBook.FCurrentItemIndex >= Count - 1) then
      FStyleBook.FCurrentItemIndex := 0;
  end;
end;

procedure TZxStyleCollection.SetItem(Index: Integer;
  const Value: TZxStyleCollectionItem);
begin
  inherited SetItem(Index, Value);
end;

{ TZxStyleBook }

constructor TZxStyleBook.Create(AOwner: TComponent);
begin
  inherited;
  FStyles := TZxStyleCollection.Create(Self);
  FStylesDic := TDictionary<string, TZxStyleCollectionItem>.Create;
  FCurrentItemIndex := 0;
  if csDesigning in ComponentState then
  begin
    FBeforeStyleChangingId := TMessageManager.DefaultManager.SubscribeToMessage(
      TBeforeStyleChangingMessage, BeforeStyleChangingHandler);
    FStyleChangedId := TMessageManager.DefaultManager.SubscribeToMessage(
      TStyleChangedMessage, StyleChangedHandler);
  end;
  AddCustomFindStyleResource(CustomFindStyleResource);
end;

destructor TZxStyleBook.Destroy;
begin
  RemoveCustomFindStyleResource(CustomFindStyleResource);
  if csDesigning in ComponentState then
  begin
    TMessageManager.DefaultManager.Unsubscribe(TBeforeStyleChangingMessage,
      FBeforeStyleChangingId);
    TMessageManager.DefaultManager.Unsubscribe(TStyleChangedMessage,
      FStyleChangedId);
  end;
  FreeAndNil(FStylesDic);
  FreeAndNil(FStyles);
  inherited;
end;

function TZxStyleBook.CustomFindStyleResource(const AStyleLookup: string;
  const Clone: Boolean): TFmxObject;
var
  Container: TStyleContainer;
begin
  Result := nil;
  if TStyledControl.LoadableStyle = nil then
  begin
    ChooseStyleIndex;
    Container := GetStyleContainer;
    if Container <> nil then
      Result := Container.FindStyleResource(AStyleLookup, Clone);
  end;
end;

procedure TZxStyleBook.BeforeStyleChangingHandler(const Sender: TObject;
  const Msg: TMessage);
begin
  FCurrentItemIndex := 0;
end;

procedure TZxStyleBook.StyleChangedHandler(const Sender: TObject;
  const Msg: TMessage);
begin
  if TStyleChangedMessage(Msg).Value = nil then
    ChooseStyleIndex;
end;

procedure TZxStyleBook.ChooseStyleIndex;
var
  Idx: Integer;
begin
  Idx := StyleIndexByContext(Self);
  if Idx >= 0 then
    FCurrentItemIndex := Idx;
end;

procedure TZxStyleBook.Clear;
begin
  FStyles.Clear;
  FCurrentItemIndex := 0;
end;

procedure TZxStyleBook.CollectionChanged;
begin
  RebuildDictionary;
end;

function TZxStyleBook.GetCurrentItem: TZxStyleCollectionItem;
begin
  if (FCurrentItemIndex >= 0) and (FCurrentItemIndex < FStyles.Count) then
    Result := FStyles[FCurrentItemIndex]
  else if FStyles.Count > 0 then
    Result := FStyles[0]
  else
    Result := nil;
end;

function TZxStyleBook.GetStyle: TFmxObject;
var
  Item: TZxStyleCollectionItem;
begin
  Item := GetCurrentItem;
  if Item <> nil then
    Result := Item.Style
  else
    Result := nil;
end;

function TZxStyleBook.GetStyle(const Context: TFmxObject): TFmxObject;
var
  Idx: Integer;
  Item: TZxStyleCollectionItem;
begin
  Result := nil;
  Idx := StyleIndexByContext(Context);
  if (Idx >= 0) and (Idx < FStyles.Count) then
  begin
    Item := FStyles[Idx];
    if Item <> nil then
      Result := Item.Style;
  end;
end;

function TZxStyleBook.GetStyleContainer: TStyleContainer;
var
  S: TFmxObject;
begin
  S := GetStyle;
  if S is TStyleContainer then
    Result := TStyleContainer(S)
  else
    Result := nil;
end;

procedure TZxStyleBook.Loaded;
begin
  inherited;
  if FStyleFile <> '' then
    LoadStyleFromFile;
  ChooseStyleIndex;
  if (CurrentItem <> nil) and not CurrentItem.IsEmpty then
  begin
    if UseStyleManager and not (csDesigning in ComponentState) and (Style <> nil) then
      TStyleManager.SetStyle(Style)
    else
    begin
      TMessageManager.DefaultManager.SendMessage(nil,
        TBeforeStyleChangingMessage.Create, True);
      TMessageManager.DefaultManager.SendMessage(nil,
        TStyleChangedMessage.Create(nil, nil), True);
    end;
  end;
end;

procedure TZxStyleBook.SetStyleFile(const Value: string);
begin
  if FStyleFile = Value then
    Exit;
  FStyleFile := Value;
  if csLoading in ComponentState then
    Exit;
  LoadStyleFromFile;
  // Cross-form propagation when the user retargets the file at design time.
  if csDesigning in ComponentState then
  begin
    TMessageManager.DefaultManager.SendMessage(nil,
      TBeforeStyleChangingMessage.Create, True);
    TMessageManager.DefaultManager.SendMessage(nil,
      TStyleChangedMessage.Create(nil, nil), True);
  end;
end;

function TZxStyleBook.TryOpenStyleStream: TStream;
var
  Resolved: string;
{$IFDEF MSWINDOWS}
  ResName: string;
{$ENDIF}
begin
  Result := nil;
  if FStyleFile = '' then
    Exit;

  if csDesigning in ComponentState then
  begin
    if Assigned(ZxStyleBookDesignTimeResolver) then
      Resolved := ZxStyleBookDesignTimeResolver(Self, FStyleFile)
    else
      Resolved := FStyleFile;
    if (Resolved <> '') and TFile.Exists(Resolved) then
      Result := TFileStream.Create(Resolved, fmOpenRead or fmShareDenyWrite);
    Exit;
  end;

{$IFDEF MSWINDOWS}
  ResName := UpperCase(TPath.GetFileNameWithoutExtension(FStyleFile));
  if (ResName <> '') and (FindResource(HInstance, PChar(ResName), RT_RCDATA) <> 0) then
  begin
    Result := TResourceStream.Create(HInstance, ResName, RT_RCDATA);
    Exit;
  end;
{$ENDIF}

  Resolved := TPath.Combine(ExtractFilePath(ParamStr(0)), FStyleFile);
  if TFile.Exists(Resolved) then
    Exit(TFileStream.Create(Resolved, fmOpenRead or fmShareDenyWrite));

  if TFile.Exists(FStyleFile) then
    Result := TFileStream.Create(FStyleFile, fmOpenRead or fmShareDenyWrite);
end;

procedure TZxStyleBook.LoadStyleFromFile;
var
  Stream: TStream;
  Item: TZxStyleCollectionItem;
begin
  if csDestroying in ComponentState then
    Exit;
  Stream := TryOpenStyleStream;
  if Stream = nil then
    Exit;
  try
    Clear;
    Item := FStyles.Add;
    Stream.Position := 0;
    Item.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TZxStyleBook.LoadFromStream(const Stream: TStream);
begin
  if not (csLoading in ComponentState) and
    TStyleStreaming.CanLoadFromStream(Stream) then
  begin
    Clear;
    if FStyles.Count = 0 then
      FStyles.Add;
    CurrentItem.LoadFromStream(Stream);
  end;
end;

procedure TZxStyleBook.RebuildDictionary;
var
  I: Integer;
  Item: TZxStyleCollectionItem;
begin
  if csDestroying in ComponentState then
    Exit;
  FStylesDic.Clear;
  for I := 0 to FStyles.Count - 1 do
  begin
    Item := FStyles[I];
    if (Item <> nil) and not FStylesDic.ContainsKey(Item.Platform) then
      FStylesDic.Add(Item.Platform, Item);
  end;
end;

procedure TZxStyleBook.SetStyles(const Value: TZxStyleCollection);
begin
  FStyles.Assign(Value);
end;

procedure TZxStyleBook.SetUseStyleManager(const Value: Boolean);
begin
  FUseStyleManager := Value;
end;

function TZxStyleBook.StyleIndexByContext(const Context: TFmxObject): Integer;
var
  DeviceBehavior: IInterface;
  OSPlatform: TOSPlatform;
  I: Integer;
begin
  Result := -1;
  if FStyles.Count = 0 then
    Exit;
  DeviceBehavior := TBehaviorServices.Current.GetBehaviorService(
    IDeviceBehavior, Context);
  if Supports(DeviceBehavior, IDeviceBehavior) then
  begin
    OSPlatform := (DeviceBehavior as IDeviceBehavior).GetOSPlatform(Context);
    for I := 0 to FStyles.Count - 1 do
      if SameText(FStyles[I].Platform,
        TStyleDescription.PlatformNames[OSPlatform]) then
        Exit(I);
  end;
  if FUseStyleManager and not (csDesigning in ComponentState) then
    Result := 0;
end;

initialization
  RegisterFmxClasses([TZxStyleBook]);

end.
