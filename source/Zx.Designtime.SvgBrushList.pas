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
unit Zx.Designtime.SvgBrushList;

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
  Skia.FMX.Designtime.Editor.SVG,
{$ELSE}
  FMX.Skia,
  FMX.Skia.Designtime.Editor.SVG,
{$ENDIF}
  FMX.Edit,
  Zx.SvgBrushList;

type
  TZxSvgListBoxItem = class(TListBoxItem)
  strict private[unsafe]
    FSvgBrushItem: TZxSvgBrushItem;
    FSvgStyleObject: TSkSvg;
    function GetSvgSource: TSkSvgSource;
    procedure SetSvgSource(const Value: TSkSvgSource);
    function GetItemText: String;
    procedure SetItemText(const Value: String);
  strict private
    procedure UpdateSvgStyleObject;
  strict protected
    procedure ApplyStyle; override;
    procedure FreeStyle; override;
    function DoFilterControlText(const AText: string): string; override;
  public
    constructor Create(AOwner: TComponent; const ASvgBrushItem: TZxSvgBrushItem); reintroduce;
    destructor Destroy; override;
    procedure UpdateIndex(const AUpdateCollectionItemIndex: Boolean);
    property SvgSource: TSkSvgSource read GetSvgSource write SetSvgSource;
    property ItemText: String read GetItemText write SetItemText;
  end;

  TZxSvgBrushListEditorForm = class(TForm)
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
    FSvgBrushList: TZxSvgBrushList;
    FModified: Boolean;
    procedure Load;
    procedure UpdateControls;
    procedure UpdateItemsIndices(const AUpdateCollectionItemIndex: Boolean);
    function AddItem(const ASvgBrushItem: TZxSvgBrushItem): TZxSvgListBoxItem;
  public
    function ShowModal(const ASource: TZxSvgBrushList): TModalResult; reintroduce;
  end;

implementation

resourcestring
  SUnsavedChangesMsg = 'You have unsaved changes. Close anyway?';

{$R *.fmx}
  { TZxSvgBrushListEditorForm }

function TZxSvgBrushListEditorForm.ShowModal(const ASource: TZxSvgBrushList): TModalResult;
begin
  FSvgBrushList := TZxSvgBrushList.Create(Self);
  try
    FSvgBrushList.Assign(ASource);
    Load;
    Result := inherited ShowModal;
    if Result = mrOk then
      ASource.Assign(FSvgBrushList);
  finally
    FreeAndNil(FSvgBrushList);
  end;
end;

procedure TZxSvgBrushListEditorForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
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

procedure TZxSvgBrushListEditorForm.Load;
begin
  lbItems.BeginUpdate;
  lbItems.Clear;
  for var LSvgBrush in FSvgBrushList.SvgBrushList do
    AddItem(LSvgBrush);
  lbItems.EndUpdate;
  UpdateControls;
end;

procedure TZxSvgBrushListEditorForm.UpdateControls;
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
    edItemName.Text := TZxSvgListBoxItem(lbItems.Selected).ItemText
  else
    edItemName.Text := String.Empty;
end;

procedure TZxSvgBrushListEditorForm.UpdateItemsIndices(const AUpdateCollectionItemIndex: Boolean);
begin
  for var I := 0 to Pred(lbItems.Count) do
    TZxSvgListBoxItem(lbItems.ListItems[I]).UpdateIndex(AUpdateCollectionItemIndex);
end;

function TZxSvgBrushListEditorForm.AddItem(const ASvgBrushItem: TZxSvgBrushItem): TZxSvgListBoxItem;
begin
  Result := TZxSvgListBoxItem.Create(lbItems, ASvgBrushItem);
  Result.Parent := lbItems;
end;

procedure TZxSvgBrushListEditorForm.btnAddClick(Sender: TObject);
begin
  var
  LCollectionItem := FSvgBrushList.SvgBrushList.Add;
  AddItem(LCollectionItem);
  UpdateControls;
  FModified := True;
end;

procedure TZxSvgBrushListEditorForm.btnRemoveClick(Sender: TObject);
begin
  var
  LSelected := lbItems.ItemIndex;
  if LSelected = -1 then
    Exit;
  lbItems.ListItems[LSelected].Free;
  FSvgBrushList.SvgBrushList.Delete(LSelected);
  UpdateControls;
  UpdateItemsIndices(False);
  FModified := True;
end;

procedure TZxSvgBrushListEditorForm.btnEditClick(Sender: TObject);
var
  LResult: TModalResult;
begin
  var
  LSelected := lbItems.Selected;
  if LSelected = nil then
    Exit;
  var
  LSvgSource := TZxSvgListBoxItem(LSelected).SvgSource;
  var
  LSvgEditor := TSkSvgEditorForm.Create(Application);
  try
    LResult := LSvgEditor.ShowModal(LSvgSource);
  finally
    LSvgEditor.Free;
  end;
  if LResult = mrOk then
  begin
    TZxSvgListBoxItem(LSelected).SvgSource := LSvgSource;
    FModified := True;
  end;
end;

procedure TZxSvgBrushListEditorForm.btnClearClick(Sender: TObject);
begin
  FSvgBrushList.SvgBrushList.ClearAndResetID;
  lbItems.Clear;
  UpdateControls;
  FModified := True;
end;

procedure TZxSvgBrushListEditorForm.edItemNameTyping(Sender: TObject);
begin
  if Assigned(lbItems.Selected) then
  begin
    TZxSvgListBoxItem(lbItems.Selected).ItemText := edItemName.Text;
    FModified := True;
  end;
end;

procedure TZxSvgBrushListEditorForm.lbItemsChange(Sender: TObject);
begin
  UpdateControls;
end;

procedure TZxSvgBrushListEditorForm.lbItemsDragChange(SourceItem, DestItem: TListBoxItem; var Allow: Boolean);
begin
  FModified := True;
  TThread.ForceQueue(nil,
    procedure
    begin
      UpdateItemsIndices(True);
    end);
end;

{ TZxSvgListBoxItem }

constructor TZxSvgListBoxItem.Create(AOwner: TComponent; const ASvgBrushItem: TZxSvgBrushItem);
begin
  inherited Create(AOwner);
  FSvgBrushItem := ASvgBrushItem;
  Height := 50;
  StyleLookup := 'listboxitemsvgstyle';
end;

destructor TZxSvgListBoxItem.Destroy;
begin
  FSvgBrushItem := nil;
  inherited;
end;

procedure TZxSvgListBoxItem.ApplyStyle;
begin
  inherited;
  if FindStyleResource<TSkSvg>('svg', FSvgStyleObject) then
    UpdateSvgStyleObject;
end;

procedure TZxSvgListBoxItem.FreeStyle;
begin
  FSvgStyleObject := nil;
  inherited;
end;

function TZxSvgListBoxItem.DoFilterControlText(const AText: string): string;
begin
  Result := Format('%d - %s', [Index, FSvgBrushItem.DisplayName]);
end;

function TZxSvgListBoxItem.GetSvgSource: TSkSvgSource;
begin
  Result := FSvgBrushItem.SvgBrush.Source;
end;

function TZxSvgListBoxItem.GetItemText: String;
begin
  Result := FSvgBrushItem.Name;
end;

procedure TZxSvgListBoxItem.SetSvgSource(const Value: TSkSvgSource);
begin
  FSvgBrushItem.SvgBrush.Source := Value;
  UpdateSvgStyleObject;
end;

procedure TZxSvgListBoxItem.SetItemText(const Value: String);
begin
  if FSvgBrushItem.Name <> Value then
  begin
    FSvgBrushItem.Name := Value;
    Change;
  end;
end;

procedure TZxSvgListBoxItem.UpdateIndex(const AUpdateCollectionItemIndex: Boolean);
begin
  if AUpdateCollectionItemIndex then
    FSvgBrushItem.Index := Index;
  Change;
end;

procedure TZxSvgListBoxItem.UpdateSvgStyleObject;
begin
  if Assigned(FSvgStyleObject) then
    FSvgStyleObject.SVG.Assign(FSvgBrushItem.SvgBrush);
end;

end.
