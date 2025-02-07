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
unit Zx.Designtime.AnimatedImageSourceList;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Skia,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.DialogService,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Controls.Presentation,
{$IFDEF CompilerVersion < 36}
  Skia.FMX,
  Skia.FMX.Designtime.Editor.AnimatedImage,
{$ELSE}
  FMX.Skia,
  FMX.Skia.Designtime.Editor.AnimatedImage,
{$ENDIF}
  FMX.Edit,
  Zx.AnimatedImageSourceList;

type
  TZxAnimatedImageListBoxItem = class(TListBoxItem)
  strict private[unsafe]
    FAnimatedImageSourceItem: TZxAnimatedImageSourceItem;
    FAnimatedImageStyleObject: TSkAnimatedImage;
    function GetItemText: String;
    procedure SetItemText(const Value: String);
  strict private
    function GetSourceData: TBytes;
    procedure SetSourceData(const AValue: TBytes);
    procedure UpdateAnimatedImageStyleObject;
  strict protected
    procedure ApplyStyle; override;
    procedure FreeStyle; override;
    function DoFilterControlText(const AText: string): string; override;
  public
    constructor Create(AOwner: TComponent; const AAnimatedImageSourceItem: TZxAnimatedImageSourceItem); reintroduce;
    destructor Destroy; override;
    procedure UpdateIndex(const AUpdateCollectionItemIndex: Boolean);
    property SourceData: TBytes read GetSourceData write SetSourceData;
    property ItemText: String read GetItemText write SetItemText;
  end;

  TZxAnimatedImageSourceListEditorForm = class(TForm)
    lbItems: TListBox;
    layOptions: TLayout;
    btnAdd: TSpeedButton;
    btnEdit: TSpeedButton;
    btnClear: TSpeedButton;
    btnCancel: TSpeedButton;
    btnSave: TSpeedButton;
    lblNoItems: TSkLabel;
    btnRemove: TSpeedButton;
    Styles: TStyleBook;
    edItemName: TEdit;
    procedure btnAddClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure edItemNameTyping(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lbItemsChange(Sender: TObject);
    procedure lbItemsDragChange(SourceItem, DestItem: TListBoxItem; var Allow: Boolean);
  strict private
    FAnimatedImageSourceList: TZxAnimatedImageSourceList;
    FModified: Boolean;
    procedure Load;
    procedure UpdateControls;
    procedure UpdateItemsIndices(const AUpdateCollectionItemIndex: Boolean);
    function AddItem(const AAnimatedImageSourceItem: TZxAnimatedImageSourceItem): TZxAnimatedImageListBoxItem;
  public
    function ShowModal(const ASource: TZxAnimatedImageSourceList): TModalResult; reintroduce;
  end;

implementation

resourcestring
  SUnsavedChangesMsg = 'You have unsaved changes. Close anyway?';

{$R *.fmx}
  { TZxAnimatedImageSourceListEditorForm }

function TZxAnimatedImageSourceListEditorForm.ShowModal(const ASource: TZxAnimatedImageSourceList): TModalResult;
begin
  FAnimatedImageSourceList := TZxAnimatedImageSourceList.Create(Self);
  try
    FAnimatedImageSourceList.Assign(ASource);
    Load;
    Result := inherited ShowModal;
    if Result = mrOk then
      ASource.Assign(FAnimatedImageSourceList);
  finally
    FreeAndNil(FAnimatedImageSourceList);
  end;
end;

procedure TZxAnimatedImageSourceListEditorForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  LCanClose: Boolean;
begin
  if (ModalResult = mrCancel) and FModified then
  begin
    TDialogService.MessageDialog(SUnsavedChangesMsg, TMsgDlgType.mtConfirmation, mbOKCancel, TMsgDlgBtn.mbCancel, 0,
      procedure(const AResult: TModalResult)
      begin
        LCanClose := AResult = mrOk;
      end);
    CanClose := LCanClose;
  end;
end;

procedure TZxAnimatedImageSourceListEditorForm.Load;
begin
  lbItems.BeginUpdate;
  lbItems.Clear;
  for var LItem in FAnimatedImageSourceList.SourceList do
    AddItem(LItem);
  lbItems.EndUpdate;
  UpdateControls;
end;

procedure TZxAnimatedImageSourceListEditorForm.UpdateControls;
begin
  var
  LHasItems := lbItems.Count > 0;
  var
  LIsItemSelected := lbItems.ItemIndex > -1;

  lblNoItems.Visible := not LHasItems;
  btnClear.Enabled := LHasItems;
  btnRemove.Enabled := LIsItemSelected;
  btnEdit.Enabled := LIsItemSelected;
  edItemName.Enabled := LIsItemSelected;
  if LIsItemSelected then
    edItemName.Text := TZxAnimatedImageListBoxItem(lbItems.Selected).ItemText
  else
    edItemName.Text := String.Empty;
end;

procedure TZxAnimatedImageSourceListEditorForm.UpdateItemsIndices(const AUpdateCollectionItemIndex: Boolean);
begin
  for var I := 0 to Pred(lbItems.Count) do
    TZxAnimatedImageListBoxItem(lbItems.ListItems[I]).UpdateIndex(AUpdateCollectionItemIndex);
end;

function TZxAnimatedImageSourceListEditorForm.AddItem(const AAnimatedImageSourceItem: TZxAnimatedImageSourceItem)
  : TZxAnimatedImageListBoxItem;
begin
  Result := TZxAnimatedImageListBoxItem.Create(lbItems, AAnimatedImageSourceItem);
  Result.Parent := lbItems;
end;

procedure TZxAnimatedImageSourceListEditorForm.btnAddClick(Sender: TObject);
begin
  var
  LCollectionItem := FAnimatedImageSourceList.SourceList.Add;
  AddItem(LCollectionItem);
  UpdateControls;
  FModified := True;
end;

procedure TZxAnimatedImageSourceListEditorForm.btnRemoveClick(Sender: TObject);
begin
  var
  LSelected := lbItems.ItemIndex;
  if LSelected = -1 then
    Exit;
  lbItems.ListItems[LSelected].Free;
  FAnimatedImageSourceList.SourceList.Delete(LSelected);
  UpdateControls;
  UpdateItemsIndices(False);
  FModified := True;
end;

procedure TZxAnimatedImageSourceListEditorForm.btnEditClick(Sender: TObject);
var
  LResult: TModalResult;
begin
  var
  LSelected := lbItems.Selected;
  if LSelected = nil then
    Exit;
  var
  LData := TZxAnimatedImageListBoxItem(LSelected).SourceData;
  var
  LEditor := TSkAnimatedImageEditorForm.Create(Application);
  try
    LResult := LEditor.ShowModal(LData);
  finally
    LEditor.Free;
  end;
  if LResult = mrOk then
  begin
    TZxAnimatedImageListBoxItem(LSelected).SourceData := LData;
    FModified := True;
  end;
end;

procedure TZxAnimatedImageSourceListEditorForm.btnClearClick(Sender: TObject);
begin
  FAnimatedImageSourceList.SourceList.ClearAndResetID;
  lbItems.Clear;
  UpdateControls;
  FModified := True;
end;

procedure TZxAnimatedImageSourceListEditorForm.edItemNameTyping(Sender: TObject);
begin
  if Assigned(lbItems.Selected) then
  begin
    TZxAnimatedImageListBoxItem(lbItems.Selected).ItemText := edItemName.Text;
    FModified := True;
  end;
end;

procedure TZxAnimatedImageSourceListEditorForm.lbItemsChange(Sender: TObject);
begin
  UpdateControls;
end;

procedure TZxAnimatedImageSourceListEditorForm.lbItemsDragChange(SourceItem, DestItem: TListBoxItem; var Allow: Boolean);
begin
  FModified := True;
  TThread.ForceQueue(nil,
    procedure
    begin
      UpdateItemsIndices(True);
    end);
end;

{ TZxAnimatedImageListBoxItem }

constructor TZxAnimatedImageListBoxItem.Create(AOwner: TComponent; const AAnimatedImageSourceItem: TZxAnimatedImageSourceItem);
begin
  inherited Create(AOwner);
  FAnimatedImageSourceItem := AAnimatedImageSourceItem;
  Height := 50;
  StyleLookup := 'listboxitemanimatedimagestyle';
end;

destructor TZxAnimatedImageListBoxItem.Destroy;
begin
  FAnimatedImageSourceItem := nil;
  inherited;
end;

procedure TZxAnimatedImageListBoxItem.ApplyStyle;
begin
  inherited;
  if FindStyleResource<TSkAnimatedImage>('animatedimage', FAnimatedImageStyleObject) then
    UpdateAnimatedImageStyleObject;
end;

procedure TZxAnimatedImageListBoxItem.FreeStyle;
begin
  FAnimatedImageStyleObject := nil;
  inherited;
end;

function TZxAnimatedImageListBoxItem.DoFilterControlText(const AText: string): string;
begin
  Result := Format('%d - %s', [Index, FAnimatedImageSourceItem.DisplayName]);
end;

function TZxAnimatedImageListBoxItem.GetItemText: String;
begin
  Result := FAnimatedImageSourceItem.Name;
end;

function TZxAnimatedImageListBoxItem.GetSourceData: TBytes;
begin
  Result := FAnimatedImageSourceItem.Source.Data;
end;

procedure TZxAnimatedImageListBoxItem.SetItemText(const Value: String);
begin
  if FAnimatedImageSourceItem.Name <> Value then
  begin
    FAnimatedImageSourceItem.Name := Value;
    Change;
  end;
end;

procedure TZxAnimatedImageListBoxItem.SetSourceData(const AValue: TBytes);
begin
  FAnimatedImageSourceItem.Source.Data := AValue;
  UpdateAnimatedImageStyleObject;
end;

procedure TZxAnimatedImageListBoxItem.UpdateIndex(const AUpdateCollectionItemIndex: Boolean);
begin
  if AUpdateCollectionItemIndex then
    FAnimatedImageSourceItem.Index := Index;
  Change;
end;

procedure TZxAnimatedImageListBoxItem.UpdateAnimatedImageStyleObject;
begin
  if Assigned(FAnimatedImageStyleObject) then
    FAnimatedImageStyleObject.Source.Assign(FAnimatedImageSourceItem.Source);
end;

end.
