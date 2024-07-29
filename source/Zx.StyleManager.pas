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
unit Zx.StyleManager;

interface

uses
  System.Classes,
  System.Generics.Collections,
  { Skia is necessary for its initialization/finalization units }
{$IFDEF CompilerVersion < 36}
  Skia,
  Skia.FMX,
{$ELSE}
  System.Skia,
  FMX.Skia,
{$ENDIF}
  FMX.Types,
  FMX.Controls,
  FMX.Styles;

type
  TDataModuleClass = class of TDataModule;

  IZxStylesHolder = interface
    ['{0A7BBEC4-54BA-458C-8365-201B643E7EE5}']
    procedure AddStyles(const AStyles: TArray<TFmxObject>);
    procedure Unload;
    function IsEmpty: Boolean;
  end;

  TZxStyleManager = class
  strict private
    class var FStyleHolders: TArray<IZxStylesHolder>;
    class destructor ClassDestroy;
    class function InternalAddStyles(const ASource, ATarget: TStyleContainer; AClone: Boolean): TArray<TFmxObject>;
    class function ActiveStyle: TStyleContainer;
  public
    class function CanAddStyles: Boolean;
    { First two AddStyles methods are for simple usage, where TZxStyleManager handles style unloading }
    class procedure AddStyles(ADataModuleClass: TDataModuleClass); overload;
    class procedure AddStyles(AStyleContainer: TStyleContainer; AClone: Boolean); overload;
    { Second two AddStyles methods are for custom implementation of TZxStylesHolder; style unloading needs to be manually handled }
    class procedure AddStyles(ADataModuleClass: TDataModuleClass; const AStylesHolder: IZxStylesHolder); overload;
    class procedure AddStyles(AStyleContainer: TStyleContainer; AClone: Boolean; const AStylesHolder: IZxStylesHolder); overload;
    class procedure RemoveStyles(const AStylesHodler: IZxStylesHolder);
  end;

  TZxStylesHolder = class(TInterfacedObject, IZxStylesHolder, IFreeNotification)
  strict private
    FStyles: TList<TFmxObject>;
    FUnloaded: Boolean;
    procedure OnStylesNotify(Sender: TObject; const Item: TFmxObject; Action: TCollectionNotification);
  strict private
    { IZxStylesHolder }
    procedure AddStyles(const AStyles: TArray<TFmxObject>);
    procedure Unload;
    function IsEmpty: Boolean;
    { IFreeNotification }
    procedure FreeNotification(AObject: TObject);
  strict protected
    procedure DoOnStylesNotify(Sender: TObject; const Item: TFmxObject; Action: TCollectionNotification); virtual;
    property Styles: TList<TFmxObject> read FStyles;
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;
  end;

implementation

{ TZxStyleManager }

class destructor TZxStyleManager.ClassDestroy;
begin
  for var LStylesHolder in FStyleHolders do
    RemoveStyles(LStylesHolder);
  FStyleHolders := [];
end;

class procedure TZxStyleManager.AddStyles(ADataModuleClass: TDataModuleClass);
begin
  var
  LStylesHolder := TZxStylesHolder.Create as IZxStylesHolder;
  AddStyles(ADataModuleClass, LStylesHolder);
  if not LStylesHolder.IsEmpty then
    FStyleHolders := FStyleHolders + [LStylesHolder];
end;

class procedure TZxStyleManager.AddStyles(AStyleContainer: TStyleContainer; AClone: Boolean);
begin
  var
  LStyles := InternalAddStyles(AStyleContainer, ActiveStyle, AClone);
  if Length(LStyles) > 0 then
  begin
    var
    LStylesHolder := TZxStylesHolder.Create as IZxStylesHolder;
    LStylesHolder.AddStyles(LStyles);
    FStyleHolders := FStyleHolders + [LStylesHolder];
  end;
end;

class procedure TZxStyleManager.AddStyles(ADataModuleClass: TDataModuleClass; const AStylesHolder: IZxStylesHolder);
begin
  Assert(Assigned(AStylesHolder), 'TZxStyleManager.AddStyles: AStylesHolder must be assigned');
  var
  LTarget := ActiveStyle;
  if LTarget = nil then
    Exit;
  var
  LDataModule := ADataModuleClass.Create(nil);
  try
    for var LComponent in LDataModule do
      if LComponent is TStyleBook then
      begin
        var
        LStyles := InternalAddStyles(TStyleBook(LComponent).Style as TStyleContainer, LTarget, False);
        AStylesHolder.AddStyles(LStyles);
      end;
  finally
    LDataModule.Free;
  end;
end;

class procedure TZxStyleManager.AddStyles(AStyleContainer: TStyleContainer; AClone: Boolean;
  const AStylesHolder: IZxStylesHolder);
begin
  Assert(Assigned(AStylesHolder), 'TZxStyleManager.AddStyles: AStylesHolder must be assigned');
  var
  LStyles := InternalAddStyles(AStyleContainer, ActiveStyle, AClone);
  AStylesHolder.AddStyles(LStyles);
end;

class function TZxStyleManager.InternalAddStyles(const ASource, ATarget: TStyleContainer; AClone: Boolean): TArray<TFmxObject>;
begin
  if (ASource = nil) or (ATarget = nil) then
    Exit;
  if ASource.Children = nil then
    (ASource as IBinaryStyleContainer).UnpackAllBinaries;
  SetLength(Result, ASource.ChildrenCount);
  for var I := Pred(ASource.ChildrenCount) downto 0 do
  begin
    if AClone then
      Result[I] := ASource.Children[I].Clone(ATarget)
    else
      Result[I] := ASource.Children[I];
    ATarget.AddObject(Result[I]);
  end;
end;

class procedure TZxStyleManager.RemoveStyles(const AStylesHodler: IZxStylesHolder);
begin
  AStylesHodler.Unload;
end;

class function TZxStyleManager.ActiveStyle: TStyleContainer;
begin
  Result := TStyleManager.ActiveStyle(nil) as TStyleContainer;
end;

class function TZxStyleManager.CanAddStyles: Boolean;
begin
  Result := ActiveStyle <> nil;
end;

{ TZxStylesHolder }

procedure TZxStylesHolder.AfterConstruction;
begin
  inherited;
  FStyles := TList<TFmxObject>.Create;
  FStyles.OnNotify := OnStylesNotify;
end;

destructor TZxStylesHolder.Destroy;
begin
  Unload;
  FStyles.Free;
  inherited;
end;

procedure TZxStylesHolder.FreeNotification(AObject: TObject);
begin
  var
  LIndex := FStyles.IndexOf(TFmxObject(AObject));
  if LIndex >= 0 then
    FStyles.Delete(LIndex);
end;

function TZxStylesHolder.IsEmpty: Boolean;
begin
  Result := FStyles.IsEmpty;
end;

procedure TZxStylesHolder.AddStyles(const AStyles: TArray<TFmxObject>);
begin
  if Length(AStyles) = 0 then
    Exit;
  FUnloaded := False;
  FStyles.AddRange(AStyles);
end;

procedure TZxStylesHolder.OnStylesNotify(Sender: TObject; const Item: TFmxObject; Action: TCollectionNotification);
begin
  case Action of
    TCollectionNotification.cnAdded:
      Item.AddFreeNotify(Self);
    TCollectionNotification.cnExtracted, TCollectionNotification.cnRemoved:
      Item.RemoveFreeNotify(Self);
  end;
  DoOnStylesNotify(Sender, Item, Action);
end;

procedure TZxStylesHolder.DoOnStylesNotify(Sender: TObject; const Item: TFmxObject; Action: TCollectionNotification);
begin

end;

procedure TZxStylesHolder.Unload;
begin
  if FUnloaded then
    Exit;
  FUnloaded := True;
  var
  LStyles := FStyles.ToArray;
  FStyles.Clear;
  for var LStyle in LStyles do
    LStyle.Free;
end;

end.
