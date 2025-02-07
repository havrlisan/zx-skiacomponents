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
unit Zx.Styles;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Styles,
  Zx.SvgBrushList,
  Zx.Styles.Objects,
  Zx.Text;

type
  TZxStyles = class(TDataModule)
    sbDefault: TStyleBook;
  end;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

uses
  Zx.StyleManager;

{$R *.dfm}

initialization

TZxStyleManager.AddStyles(TZxStyles);

end.
