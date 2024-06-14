{************************************************************************}
{                                                                        }
{                           Zx-SkiaComponents                            }
{                                                                        }
{ Copyright (c) 2024 Zx-SkiaComponents Project.                          }
{                                                                        }
{ Use of this source code is governed by the MIT license that can be     }
{ found in the LICENSE file.                                             }
{                                                                        }
{************************************************************************}
unit Zx.AnimatedImageSourceList;

interface

uses
  System.Classes,
  System.SysUtils,
  System.ImageList,
  System.UITypes,
  System.Types,
{$IFDEF CompilerVersion < 36}
  Skia,
  Skia.FMX,
{$ELSE}
  FMX.Skia,
  System.Skia,
{$ENDIF}
  FMX.ImgList,
  FMX.Utils,
  FMX.Types,
  FMX.Controls,
  FMX.ActnList,
  Zx.Controls;

type
  TZxAnimatedImageSourceList = class;

  TZxAnimatedImageSourceItemClass = class of TZxAnimatedImageSourceItem;

  TZxAnimatedImageSourceItem = class(TCollectionItem)
  public const
    CDefaultDesktopSize = 16;

  strict private
    FSource: TSkAnimatedImage.TSource;
    procedure SetSource(const Value: TSkAnimatedImage.TSource);
  private
    FName: String;
    procedure SetName(const Value: String);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function GetDisplayName: string; override;
  published
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    property Source: TSkAnimatedImage.TSource read FSource write SetSource;
    property Name: String read FName write SetName;
  end;

  TZxAnimatedImageSourceCollection = class(TOwnedCollection)
  private type
    TZxAnimatedImageSourceCollectionEnumerator = class(TCollectionEnumerator)
    public
      function GetCurrent: TZxAnimatedImageSourceItem; inline;
      function MoveNext: Boolean; inline;
      property Current: TZxAnimatedImageSourceItem read GetCurrent;
    end;

  strict private[weak]
    FOwner: TZxAnimatedImageSourceList;
    function GetItem(AIndex: Integer): TZxAnimatedImageSourceItem;
    procedure SetItem(AIndex: Integer; const AValue: TZxAnimatedImageSourceItem);
  strict private
    function IndexOf(const AName: string): Integer;
    function GetItemByName(const AName: string): TZxAnimatedImageSourceItem;
  protected
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent; AItemClass: TZxAnimatedImageSourceItemClass);
    function GetEnumerator: TZxAnimatedImageSourceCollectionEnumerator; inline;
    function Add: TZxAnimatedImageSourceItem; reintroduce; overload;
    function Add(const ASource: TSkAnimatedImage.TSource): TZxAnimatedImageSourceItem; overload;
    function Insert(AIndex: Integer): TZxAnimatedImageSourceItem;
    property ItemByName[const AName: string]: TZxAnimatedImageSourceItem read GetItemByName;
    property Items[AIndex: Integer]: TZxAnimatedImageSourceItem read GetItem write SetItem; default;
  end;

  [ComponentPlatformsAttribute(SkSupportedPlatformsMask)]
  TZxAnimatedImageSourceList = class(TBaseImageList)
  private
    FCollection: TZxAnimatedImageSourceCollection;
    FOnChange: TNotifyEvent;
    procedure SetCollection(const Value: TZxAnimatedImageSourceCollection);
  protected
    procedure DoChange; override;
    function GetCount: Integer; override;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function SourceExists(const Index: Integer): Boolean;
    function Source(const AIndex: Integer): TSkAnimatedImage.TSource;
  published
    property SourceList: TZxAnimatedImageSourceCollection read FCollection write SetCollection;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{ TZxAnimatedImageSourceItem }

constructor TZxAnimatedImageSourceItem.Create(Collection: TCollection);
begin
  inherited;
  FSource := TSkAnimatedImage.TSource.Create(nil);
end;

destructor TZxAnimatedImageSourceItem.Destroy;
begin
  FSource.Free;
  inherited;
end;

procedure TZxAnimatedImageSourceItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TZxAnimatedImageSourceItem then
  begin
    TZxAnimatedImageSourceItem(Dest).FName := FName;
    TZxAnimatedImageSourceItem(Dest).FSource.Assign(FSource);
  end
  else
    inherited;
end;

function TZxAnimatedImageSourceItem.GetDisplayName: string;
begin
  Result := Name;
  if Result.IsEmpty then
    Result := 'Item ' + Index.ToString;
end;

procedure TZxAnimatedImageSourceItem.SetName(const Value: String);
begin
  FName := Value;
end;

procedure TZxAnimatedImageSourceItem.SetSource(const Value: TSkAnimatedImage.TSource);
begin
  FSource.Assign(Value);
end;

{ TZxAnimatedImageSourceCollection.TZxAnimatedImageSourceCollectionEnumerator }

function TZxAnimatedImageSourceCollection.TZxAnimatedImageSourceCollectionEnumerator.GetCurrent: TZxAnimatedImageSourceItem;
begin
  Result := TZxAnimatedImageSourceItem(inherited GetCurrent);
end;

function TZxAnimatedImageSourceCollection.TZxAnimatedImageSourceCollectionEnumerator.MoveNext: Boolean;
begin
  Result := inherited MoveNext;
end;

{ TZxAnimatedImageSourceCollection }

constructor TZxAnimatedImageSourceCollection.Create(AOwner: TPersistent; AItemClass: TZxAnimatedImageSourceItemClass);
begin
  ValidateInheritance(AOwner, TZxAnimatedImageSourceList, False);
  inherited Create(AOwner, AItemClass);
  FOwner := TZxAnimatedImageSourceList(AOwner);
end;

function TZxAnimatedImageSourceCollection.Add: TZxAnimatedImageSourceItem;
begin
  Result := inherited Add as TZxAnimatedImageSourceItem;
end;

function TZxAnimatedImageSourceCollection.Add(const ASource: TSkAnimatedImage.TSource): TZxAnimatedImageSourceItem;
begin
  Result := inherited Add as TZxAnimatedImageSourceItem;
  Result.Source := ASource;
end;

function TZxAnimatedImageSourceCollection.GetEnumerator: TZxAnimatedImageSourceCollectionEnumerator;
begin
  Result := TZxAnimatedImageSourceCollectionEnumerator.Create(Self);
end;

function TZxAnimatedImageSourceCollection.GetItem(AIndex: Integer): TZxAnimatedImageSourceItem;
begin
  Result := inherited GetItem(AIndex) as TZxAnimatedImageSourceItem;
end;

function TZxAnimatedImageSourceCollection.GetItemByName(const AName: string): TZxAnimatedImageSourceItem;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);
  if LIndex = -1 then
    Result := nil
  else
    Result := Items[LIndex];
end;

function TZxAnimatedImageSourceCollection.IndexOf(const AName: string): Integer;
begin
  Result := -1;
  for var I := 0 to Pred(Count) do
    if string.Compare(AName, Items[I].Name, [TCompareOption.coIgnoreCase]) = 0 then
    begin
      Result := I;
      Break;
    end;
end;

function TZxAnimatedImageSourceCollection.Insert(AIndex: Integer): TZxAnimatedImageSourceItem;
begin
  Result := inherited Insert(AIndex) as TZxAnimatedImageSourceItem;
end;

procedure TZxAnimatedImageSourceCollection.SetItem(AIndex: Integer; const AValue: TZxAnimatedImageSourceItem);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TZxAnimatedImageSourceCollection.Update(AItem: TCollectionItem);
begin
  inherited;
  if not(csDestroying in FOwner.ComponentState) then
    FOwner.Change;
end;

{ TZxAnimatedImageSourceList }

procedure TZxAnimatedImageSourceList.Assign(Source: TPersistent);
begin
  if Source is TZxAnimatedImageSourceList then
    FCollection.Assign(TZxAnimatedImageSourceList(Source).SourceList)
  else
    inherited;
end;

constructor TZxAnimatedImageSourceList.Create(Owner: TComponent);
begin
  inherited;
  FCollection := TZxAnimatedImageSourceCollection.Create(Self, TZxAnimatedImageSourceItem);
end;

destructor TZxAnimatedImageSourceList.Destroy;
begin
  FCollection.Free;
  inherited;
end;

procedure TZxAnimatedImageSourceList.DoChange;
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TZxAnimatedImageSourceList.GetCount: Integer;
begin
  Result := FCollection.Count;
end;

procedure TZxAnimatedImageSourceList.SetCollection(const Value: TZxAnimatedImageSourceCollection);
begin
  FCollection.Assign(Value);
end;

function TZxAnimatedImageSourceList.Source(const AIndex: Integer): TSkAnimatedImage.TSource;
begin
  if (AIndex >= 0) and (AIndex < FCollection.Count) then
    Result := FCollection[AIndex].Source
  else
    Result := nil;
end;

function TZxAnimatedImageSourceList.SourceExists(const Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < FCollection.Count);
end;

end.
