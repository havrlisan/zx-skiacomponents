unit Zx.SvgBrushList;

interface

uses
  System.Classes,
  System.SysUtils,
  System.ImageList,
  System.UITypes,
  System.Types,
  System.Skia,
  FMX.Skia,
  FMX.ImgList,
  FMX.Utils,
  FMX.Types,
  FMX.Controls,
  FMX.ActnList,
  FMX.Skia.Canvas;

type
  TZxSvgBrushList = class;

  TSynFMXSvgBrushItemClass = class of TZxSvgBrushItem;

  TZxSvgBrushItem = class(TCollectionItem)
  public const
    CDefaultDesktopSize = 16;

  strict private
    FSvgBrush: TSkSvgBrush;
    procedure SetSvgBrush(const Value: TSkSvgBrush);
  private
    FName: String;
    procedure SetName(const Value: String);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function GetDisplayName: string; override;
  published
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    property SvgBrush: TSkSvgBrush read FSvgBrush write SetSvgBrush;
    property Name: String read FName write SetName;
  end;

  TZxSvgBrushCollection = class(TOwnedCollection)
  strict private[weak]
    FOwner: TZxSvgBrushList;
    function GetItem(AIndex: Integer): TZxSvgBrushItem;
    procedure SetItem(AIndex: Integer; const AValue: TZxSvgBrushItem);
  strict private
    function IndexOf(const AName: string): Integer;
    function GetItemByName(const AName: string): TZxSvgBrushItem;
  protected
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent; AItemClass: TSynFMXSvgBrushItemClass);
    function Add(const ABrush: TSkSvgBrush): TZxSvgBrushItem; overload;
    function Insert(AIndex: Integer): TZxSvgBrushItem;
    property ItemByName[const AName: string]: TZxSvgBrushItem read GetItemByName;
    property Items[AIndex: Integer]: TZxSvgBrushItem read GetItem write SetItem; default;
  end;

  [ComponentPlatformsAttribute(pidAllPlatforms)]
  TZxSvgBrushList = class(TBaseImageList)
  private
    FCollection: TZxSvgBrushCollection;
    FOnChange: TNotifyEvent;
    procedure SetCollection(const Value: TZxSvgBrushCollection);
  private
  protected
    /// <summary> The method should perform several actions to reflect changes in the image list. Never call this
    /// method yourself, but you can to use calling <b>Change</b></summary>
    procedure DoChange; override;
    /// <summary> The getter of property <b>Count</b>. This method must be overridden in heir </summary>
    function GetCount: Integer; override;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
    /// <summary> Returns <c>True</c> if the <b>Index</b> element in the <b>Source</b> collection contains some
    /// graphical data that can be used to create an image </summary>
    function SvgBrushExists(const Index: Integer): Boolean;
    function SvgBrush(const AIndex: Integer): TSkSvgBrush;
    function SvgSource(const AIndex: Integer): TSkSvgSource;
  published
    property SvgBrushList: TZxSvgBrushCollection read FCollection write SetCollection;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  [ComponentPlatformsAttribute(pidAllPlatforms)]
  TZxSvgGlyph = class(TSkCustomControl, IGlyph)
  public const
    DesignBorderColor = $A080D080;
  private
    FImageLink: TImageLink;
    FIsChanging: Boolean;
    FIsChanged: Boolean;
    FAutoHide: Boolean;
    FOnChanged: TNotifyEvent;
    FSvgBrushExists: Boolean;
    function GetImages: TZxSvgBrushList;
    procedure SetImages(const Value: TZxSvgBrushList);
    { IGlyph }
    function GetImageIndex: TImageIndex;
    procedure SetImageIndex(const Value: TImageIndex);
    function GetImageList: TBaseImageList; inline;
    procedure SetImageList(const Value: TBaseImageList);
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
    procedure SetAutoHide(const Value: Boolean);
  protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure Loaded; override;
    procedure DoEndUpdate; override;
    /// <summary> This vitrual method is calling event <b>OnChanged</b> and method <b>Redraw</b>. <b>DoChanged</b>
    /// method is called in <b>ImagesChanged</b>. You shouldn't call this method manually </summary>
    procedure DoChanged; virtual;
    /// <summary> This method is updating properties <b>SvgBrushExists</b>, and <b>Visible</b> in case if
    /// <b>AutoHide</b> is true </summary>
    procedure UpdateVisible;
    procedure ActionChange(Sender: TBasicAction; CheckDefaults: Boolean); override;
    /// <summary> Determines whether the <b>ImageIndex</b> property needs to be stored in the fmx-file</summary>
    /// <returns> <c>True</c> if the <b>ImageIndex</b> property needs to be stored in the fmx-file</returns>
    function ImageIndexStored: Boolean; virtual;
    /// <summary> Determines whether the <b>Images</b> property needs to be stored in the fmx-file </summary>
    /// <returns> <c>True</c> if the <b>Images</b> property needs to be stored in the fmx-file</returns>
    function ImagesStored: Boolean; virtual;
    procedure SetVisible(const Value: Boolean); override;
    function VisibleStored: Boolean; override;
    function GetDefaultSize: TSizeF; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    /// <summary> Should be called when you change an instance or reference to instance of <b>TBaseImageList</b> or the
    /// <b>ImageIndex</b> property
    /// <para>See also <b>FMX.ActnList.IGlyph</b></para></summary>
    /// <remarks> This method is executed after change list of images. If TGlyph not in state Loading, Destroying,
    /// Updating then this method call <b>DoChanged</b>, otherwise only set property <b>IsChanged</b> to true</remarks>
    procedure ImagesChanged;
    /// <summary> Is <c>True</c> if <b>Images</b> is not <c>nil</c> and <b>ImageIndex</b> points to an existing picture.
    /// <para>See also <b>UpdateVisible</b>, <b>TZxSvgBrushList.SvgBrushExists</b></para></summary>
    property SvgBrushExists: Boolean read FSvgBrushExists;
    /// <summary> If there have been some changes (which needed to paint) but not executed method DoChanged yet, then
    /// this property is set to True, otherwise False</summary>
    property IsChanged: Boolean read FIsChanged write FIsChanged;
  published
    property Action;
    /// <summary> If <c>True</c>, then: at run time <b>Visible</b> property depends only on <b>SvgBrushExists</b>'s value;
    /// at designtime <b>Visible</b> is always <c>True</c>. Otherwise, <b>Visible</b>'s value can be set
    /// programmatically</summary>
    property AutoHide: Boolean read FAutoHide write SetAutoHide default True;
    property Enabled;
    property Padding;
    property Margins;
    property Align;
    property Anchors;
    property Position;
    property Width;
    property Height;
    property Opacity;
    property Visible;
    property Size;
    /// <summary> Zero based index of an image. The default is <c>-1</c>.
    /// <para> See also <b>FMX.ActnList.IGlyph</b></para></summary>
    /// <remarks> If non-existing index is specified, an image is not drawn and no exception is raised</remarks>
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex stored ImageIndexStored;
    /// <summary> The list of images. Can be <c>nil</c>. <para>See also <b>FMX.ActnList.IGlyph</b></para></summary>
    property Images: TZxSvgBrushList read GetImages write SetImages stored ImagesStored;
    /// <summary> This event handler is called after some changes in list of images and before painting </summary>
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnPaint;
    property OnPainting;
  end;

implementation

uses
  FMX.Graphics,
  System.Math;

{ TZxSvgBrushItem }

constructor TZxSvgBrushItem.Create(Collection: TCollection);
begin
  inherited;
  FSvgBrush := TSkSvgBrush.Create;
end;

destructor TZxSvgBrushItem.Destroy;
begin
  FSvgBrush.Free;
  inherited;
end;

procedure TZxSvgBrushItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TZxSvgBrushItem then
  begin
    TZxSvgBrushItem(Dest).FName := FName;
    TZxSvgBrushItem(Dest).FSvgBrush.Assign(FSvgBrush);
  end
  else
    inherited;
end;

function TZxSvgBrushItem.GetDisplayName: string;
begin
  Result := Name;
  if Result.IsEmpty then
    Result := 'Item ' + Index.ToString;
end;

procedure TZxSvgBrushItem.SetName(const Value: String);
begin
  FName := Value;
end;

procedure TZxSvgBrushItem.SetSvgBrush(const Value: TSkSvgBrush);
begin
  FSvgBrush.Assign(Value);
end;

{ TZxSvgBrushCollection }

constructor TZxSvgBrushCollection.Create(AOwner: TPersistent; AItemClass: TSynFMXSvgBrushItemClass);
begin
  ValidateInheritance(AOwner, TZxSvgBrushList, False);
  inherited Create(AOwner, AItemClass);
  FOwner := TZxSvgBrushList(AOwner);
end;

function TZxSvgBrushCollection.Add(const ABrush: TSkSvgBrush): TZxSvgBrushItem;
begin
  Result := inherited Add as TZxSvgBrushItem;
  Result.SvgBrush := ABrush;
end;

function TZxSvgBrushCollection.GetItem(AIndex: Integer): TZxSvgBrushItem;
begin
  Result := inherited GetItem(AIndex) as TZxSvgBrushItem;
end;

function TZxSvgBrushCollection.GetItemByName(const AName: string): TZxSvgBrushItem;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);
  if LIndex = -1 then
    Result := nil
  else
    Result := Items[LIndex];
end;

function TZxSvgBrushCollection.IndexOf(const AName: string): Integer;
begin
  Result := -1;
  for var I := 0 to Pred(Count) do
    if string.Compare(AName, Items[I].Name, [TCompareOption.coIgnoreCase]) = 0 then
    begin
      Result := I;
      Break;
    end;
end;

function TZxSvgBrushCollection.Insert(AIndex: Integer): TZxSvgBrushItem;
begin
  Result := inherited Insert(AIndex) as TZxSvgBrushItem;
end;

procedure TZxSvgBrushCollection.SetItem(AIndex: Integer; const AValue: TZxSvgBrushItem);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TZxSvgBrushCollection.Update(AItem: TCollectionItem);
begin
  inherited;
  if not(csDestroying in FOwner.ComponentState) then
    FOwner.Change;
end;

{ TZxSvgBrushList }

constructor TZxSvgBrushList.Create(Owner: TComponent);
begin
  inherited;
  FCollection := TZxSvgBrushCollection.Create(Self, TZxSvgBrushItem);
end;

destructor TZxSvgBrushList.Destroy;
begin
  FCollection.Free;
  inherited;
end;

procedure TZxSvgBrushList.DoChange;
begin
  inherited;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TZxSvgBrushList.GetCount: Integer;
begin
  Result := FCollection.Count;
end;

procedure TZxSvgBrushList.SetCollection(const Value: TZxSvgBrushCollection);
begin
  FCollection.Assign(Value);
end;

function TZxSvgBrushList.SvgBrush(const AIndex: Integer): TSkSvgBrush;
begin
  if (AIndex >= 0) and (AIndex < FCollection.Count) then
    Result := FCollection[AIndex].SvgBrush
  else
    Result := nil;
end;

function TZxSvgBrushList.SvgSource(const AIndex: Integer): TSkSvgSource;
begin
  if (AIndex >= 0) and (AIndex < FCollection.Count) then
    Result := FCollection[AIndex].SvgBrush.Source
  else
    Result := String.Empty;
end;

function TZxSvgBrushList.SvgBrushExists(const Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < FCollection.Count);
end;

type
  TSynFMXGlyphImageLinkEx = class(TGlyphImageLink)
  protected
    procedure Change; override;
  public
    constructor Create(AOwner: TZxSvgGlyph); reintroduce;
  end;

  { TSynFMXGlyphImageLinkEx }

constructor TSynFMXGlyphImageLinkEx.Create(AOwner: TZxSvgGlyph);
begin
  inherited Create(AOwner);
end;

procedure TSynFMXGlyphImageLinkEx.Change;
begin
  if not(csDestroying in Owner.ComponentState) then
  begin
    if not(csLoading in Owner.ComponentState) then
      TZxSvgGlyph(Owner).UpdateVisible;
    Glyph.ImagesChanged;
  end;
end;

{ TZxSvgGlyph }

constructor TZxSvgGlyph.Create(AOwner: TComponent);
begin
  inherited;
  SetAcceptsControls(False);
  HitTest := False;
  FAutoHide := True;
  TabStop := False;
  FImageLink := TSynFMXGlyphImageLinkEx.Create(Self);
  DrawCacheKind := TSkDrawCacheKind.Always;
end;

destructor TZxSvgGlyph.Destroy;
begin
  FreeAndNil(FImageLink);
  inherited;
end;

procedure TZxSvgGlyph.AfterConstruction;
begin
  inherited;
  UpdateVisible;
end;

procedure TZxSvgGlyph.Loaded;
begin
  inherited;
  UpdateVisible;
end;

procedure TZxSvgGlyph.DoChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
  Redraw;
end;

procedure TZxSvgGlyph.DoEndUpdate;
begin
  inherited;
  if FIsChanged then
    ImagesChanged;
end;

procedure TZxSvgGlyph.ActionChange(Sender: TBasicAction; CheckDefaults: Boolean);
begin
  if (Sender is TCustomAction) and not CheckDefaults then
  begin
    ImageIndex := TCustomAction(Sender).ImageIndex;
    if (TCustomAction(Sender).ActionList <> nil) and (TCustomAction(Sender).ActionList.Images is TZxSvgBrushList) then
      Images := TZxSvgBrushList(TCustomAction(Sender).ActionList.Images)
    else
      Images := nil;
  end;
  inherited;
end;

procedure TZxSvgGlyph.ImagesChanged;
begin
  if not FIsChanging then
  begin
    if ([csLoading, csDestroying, csUpdating] * ComponentState = []) and not IsUpdating then
    begin
      FIsChanging := True;
      try
        UpdateVisible;
        DoChanged;
      finally
        FIsChanged := False;
        FIsChanging := False;
      end;
    end
    else
      FIsChanged := True;
  end;
end;

procedure TZxSvgGlyph.SetVisible(const Value: Boolean);
begin
  if FAutoHide then
    inherited SetVisible(((csDesigning in ComponentState) and not Locked and not FInPaintTo) or SvgBrushExists)
  else
    inherited;
end;

function TZxSvgGlyph.VisibleStored: Boolean;
begin
  if FAutoHide then
    Result := False
  else
    Result := inherited;
end;

procedure TZxSvgGlyph.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
const
  MinCrossSize = 3;
  MaxCrossSize = 13;
var
  SvgBrush: TSkSvgBrush;
  CrossSize: Single;
begin
  inherited;
  if [csLoading, csDestroying] * ComponentState <> [] then
    Exit;
  var
  DrawRect := LocalRect;
  SvgBrush := nil;
  if (Images <> nil) and (DrawRect.Width >= 1) and (DrawRect.Height >= 1) and (ImageIndex <> -1) and
    ([csLoading, csUpdating, csDestroying] * Images.ComponentState = []) then
    SvgBrush := Images.SvgBrush(ImageIndex);
  if (csDesigning in ComponentState) and not Locked then
    DrawDesignBorder(DesignBorderColor, DesignBorderColor);
  if Assigned(SvgBrush) then
    SvgBrush.Render(ACanvas, DrawRect, AbsoluteOpacity);
  if (csDesigning in ComponentState) and not Locked and not FInPaintTo then
  begin
    DrawRect.Inflate(0.5, 0.5);
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := TAlphaColorRec.Darkgray;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
    Canvas.Stroke.Thickness := 1;
    CrossSize := Trunc(Min(MaxCrossSize, Min(DrawRect.Width, DrawRect.Height) / 6)) + 1;
    if CrossSize >= MinCrossSize then
    begin
      DrawRect.TopLeft.Offset(2, 2);
      DrawRect.BottomRight := DrawRect.TopLeft;
      DrawRect.BottomRight.Offset(CrossSize, CrossSize);
      if SvgBrush = nil then
      begin
        if Images = nil then
          Canvas.Stroke.Color := TAlphaColorRec.Red;
        Canvas.DrawLine(DrawRect.TopLeft, DrawRect.BottomRight, AbsoluteOpacity);
        Canvas.DrawLine(TPointF.Create(DrawRect.Right, DrawRect.Top), TPointF.Create(DrawRect.Left, DrawRect.Bottom),
          AbsoluteOpacity);
        DrawRect := TRectF.Create(DrawRect.Left, DrawRect.Bottom, Width, Height);
      end;
      if ImageIndex <> -1 then
      begin
        Canvas.Font.Family := 'Small Font';
        Canvas.Font.Size := 7;
        DrawRect.Bottom := DrawRect.Top + Canvas.TextHeight(Inttostr(ImageIndex));
        if DrawRect.Bottom <= Height then
        begin
          Canvas.Fill.Color := TAlphaColorRec.Darkgray;
          Canvas.FillText(DrawRect, Inttostr(ImageIndex), False, AbsoluteOpacity, [], TTextAlign.Leading, TTextAlign.Leading);
        end;
      end;
    end;
  end;
end;

function TZxSvgGlyph.GetImageList: TBaseImageList;
begin
  Result := GetImages;
end;

procedure TZxSvgGlyph.SetImageList(const Value: TBaseImageList);
begin
  ValidateInheritance(Value, TZxSvgBrushList);
  SetImages(TZxSvgBrushList(Value));
end;

function TZxSvgGlyph.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(TZxSvgBrushItem.CDefaultDesktopSize, TZxSvgBrushItem.CDefaultDesktopSize);
end;

function TZxSvgGlyph.GetImageIndex: TImageIndex;
begin
  Result := FImageLink.ImageIndex;
end;

procedure TZxSvgGlyph.UpdateVisible;
begin
  FSvgBrushExists := (Images <> nil) and Images.SvgBrushExists(ImageIndex);
  if FAutoHide then
    Visible := FSvgBrushExists;
end;

procedure TZxSvgGlyph.SetAutoHide(const Value: Boolean);
begin
  if FAutoHide <> Value then
  begin
    FAutoHide := Value;
    if (csLoading in ComponentState) and not FAutoHide then
      Visible := True
    else
      UpdateVisible;
  end;
end;

procedure TZxSvgGlyph.SetImageIndex(const Value: TImageIndex);
begin
  if FImageLink.ImageIndex <> Value then
    FImageLink.ImageIndex := Value;
end;

function TZxSvgGlyph.ImageIndexStored: Boolean;
begin
  Result := ActionClient or (ImageIndex <> -1);
end;

function TZxSvgGlyph.GetImages: TZxSvgBrushList;
begin
  Result := TZxSvgBrushList(FImageLink.Images);
end;

procedure TZxSvgGlyph.SetImages(const Value: TZxSvgBrushList);
begin
  FImageLink.Images := Value;
end;

function TZxSvgGlyph.ImagesStored: Boolean;
begin
  if ActionClient then
    Result := True
  else
    Result := Images <> nil;
end;

initialization

RegisterClasses([TZxSvgBrushList, TZxSvgBrushCollection, TZxSvgBrushItem]);
RegisterFmxClasses([TZxSvgGlyph]);

end.
