unit Zx.StyleManager;

interface

uses
  System.Classes,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Styles;

type
  IZxStylesHolder = interface
    ['{0A7BBEC4-54BA-458C-8365-201B643E7EE5}']
  end;

  TZxStyleManager = class
  private type
    TDataModuleClass = class of TDataModule;

  private
    class function InternalAddStyles(const ASource, ATarget: TStyleContainer; AClone: Boolean): TArray<TFmxObject>;
    class function ActiveStyle: TStyleContainer;
  public
    class function CanAddStyles: Boolean;
    class function AddStyles(const ADataModuleClass: TDataModuleClass): IZxStylesHolder; overload;
    class function AddStyles(const AStyleContainer: TStyleContainer; const AClone: Boolean): IZxStylesHolder; overload;
    class procedure RemoveStyles(const AStylesHodler: IZxStylesHolder);
  end;

implementation

type
  TZxStylesHolder = class(TInterfacedObject, IZxStylesHolder, IFreeNotification)
  strict private
    FStyles: TList<TFmxObject>;
    FUnloaded: Boolean;
    procedure OnStylesNotify(Sender: TObject; const Item: TFmxObject; Action: TCollectionNotification);
  protected
    { IFreeNotification }
    procedure FreeNotification(AObject: TObject);
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;
    procedure AddStyles(const AStyles: TArray<TFmxObject>);
    procedure Unload;
  end;

  { TZxStyleManager }

class function TZxStyleManager.AddStyles(const ADataModuleClass: TDataModuleClass): IZxStylesHolder;
begin
  Result := TZxStylesHolder.Create;
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
        TZxStylesHolder(Result).AddStyles(LStyles);
      end;
  finally
    LDataModule.Free;
  end;
end;

class function TZxStyleManager.AddStyles(const AStyleContainer: TStyleContainer; const AClone: Boolean): IZxStylesHolder;
begin
  Result := TZxStylesHolder.Create;
  var
  LStyles := InternalAddStyles(AStyleContainer, ActiveStyle, AClone);
  TZxStylesHolder(Result).AddStyles(LStyles);
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
  TZxStylesHolder(AStylesHodler).Unload;
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

procedure TZxStylesHolder.AddStyles(const AStyles: TArray<TFmxObject>);
begin
  FUnloaded := False;
  FStyles.AddRange(AStyles);
end;

procedure TZxStylesHolder.OnStylesNotify(Sender: TObject; const Item: TFmxObject; Action: TCollectionNotification);
begin
  case Action of
    cnAdded:
      Item.AddFreeNotify(Self);
    cnExtracted, cnRemoved:
      Item.RemoveFreeNotify(Self);
  end;
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
