<p align="center"><img src="Resources/Logo/ZX-dark.svg" alt="Logo" height="210" width="240" /></p>
<p align="center"><a href="#compatibility"><img src="https://img.shields.io/static/v1?label=RAD%20Studio&message=11%2B&color=silver&style=flat&logo=delphi&logoColor=white" alt="Delphi 12.3 support" /></a></p>

An open-source set of Delphi components for the FireMonkey framework that utilizes the **[Skia4Delphi](https://skia4delphi.org)** library.

# Summary
- [Base controls](#base-controls)
- [Svg components](#svg-components)
  - [TZxSvgGlyph](#tzxsvgglyph)
  - [TZxSvgBrushList](#tzxsvgbrushlist)
- [Animated image components](#animated-image-components)
  - [TZxAnimatedImageSourceList](#tzxanimatedimagesourcelist)
- [Text components](#text-components)
  - [TZxText](#tzxtext)
  - [TZxTextControl](#tzxtextcontrol)
  - [TZxCustomButton](#tzxcustombutton)
    - [TZxButton, TZxSpeedButton](#tzxbutton-and-tzxspeedbutton)
- [FMX style objects - revamped](#fmx-style-objects---revamped)
  - [TZxCustomActiveStyleObject](#tzxcustomactivestyleobject)
    - [TZxColorActiveStyleObject](#tzxcoloractivestyleobject)
    - [TZxAnimatedImageActiveStyleObject](#tzxanimatedimageactivestyleobject)
  - [TZxCustomButtonStyleObject](#tzxcustombuttonstyleobject)
    - [TZxColorButtonStyleObject](#tzxcolorbuttonstyleobject)
  - [TZxCustomTextButtonStyleObject](#tzxcustomtextbuttonstyleobject)
    - [TZxTextSettingsButtonStyleObject](#tzxtextsettingsbuttonstyleobject)
  - [TZxCustomSvgGlyphButtonStyleObject](#tzxcustomsvgglyphbuttonstyleobject)
    - [TZxColorOverrideSvgGlyphButtonStyleObject](#tzxcoloroverridesvgglyphbuttonstyleobject)
- [Adding default style for components](#adding-default-style-for-components)
  - [How to use](#how-to-use)
  - [Advantages and disadvantages](#advantages-and-disadvantages)

## Base controls
ZX defines the `TZxCustomControl` and `TZxStyledControl` classes, which inherit from `TSkCustomControl` and `TSkStyledControl`, respectively. They implement only a workaround for an FMX behavior on mobile platforms: panning and releasing execute _Click_ on the control on which you released your finger. This is especially annoying when you're scrolling through clickable components. The most simple workaround I found was the following:
```delphi
procedure TZxCustomControl.Click;
begin
{$IFDEF ZX_FIXMOBILECLICK}
  if FManualClick then
{$ENDIF}
    inherited;
  DoClick;
end;

procedure TZxCustomControl.Tap(const Point: TPointF);
begin
{$IFDEF ZX_FIXMOBILECLICK}
  FManualClick := True;
  Click;
  FManualClick := False;
{$ENDIF}
  inherited;
  DoTap(Point);
end;
```
This way, _Click_ only executes from the _Tap_ method, and _Tap_ is executed only if the internal calculation concluded it was a tap, not a pan. With this implementation, it is enough to assign only _OnClick_ events for all platforms, instead of assigning both _OnClick_ and _OnTap_ events, and then wrap the _OnClick_ implementation into a compiler directive condition.

_Note:_ I left this feature disabled by default since I'm unsure on how it may impact someone's existing code. I've also marked both _Click_ and _Tap_ methods as _final_ overrides and added new _DoClick_ and _DoTap_ methods, since it would be easy to break the fix by overriding those in a descendant class. To enable it, go to _Project > Options > Delphi Compiler_, and in _Conditional defines_ add `ZX_FIXMOBILECLICK`.

## Svg components
Thanks to _skia4delphi_, we have a proper [SVG support](https://github.com/skia4delphi/skia4delphi/blob/main/Documents/SVG.md) in Delphi!

### TZxSvgGlyph
ZX provides a new glyph component that draws SVG instead of a bitmap. The class implements the `IGlyph` interface and is almost the same implementation as in `TGlyph` (with properties such as _AutoHide_) but without all the bitmap-related code.

### TZxSvgBrushList
This class inherits from `TBaseImageList` and is a collection of `TSkSvgBrush` items. This implementation allows you to, for example, attach the `TZxSvgBrushList` component to a `TActionList.ImageList`, and then use the brushes by assigning `TAction.ImageIndex`. To display an item, use the above-mentioned `TZxSvgGlyph`. The component also has a design-time editor.

## Animated image components

### TZxAnimatedImageSourceList
With implementation very similar to ([`TZxSvgBrushList`](#TZxSvgBrushList)), this component stores a list of sources that can then be assigned to [`TSkAnimatedImage`](https://github.com/skia4delphi/skia4delphi/blob/main/Documents/ANIMATED-IMAGES.md)'s _Source_ property. The component also has a design-time editor. 


## Text components
Since the arrival of _skia4delphi_, we're able to:
- manipulate more text settings with the `TSkTextSettings`, such as _MaxLines_, _LetterSpacing_, font's _Weight_ and _Stretch_, etc.
- define a [custom style](https://github.com/skia4delphi/skia4delphi/blob/main/Documents/LABEL.md#firemonkey-styles) for text settings, and
- retrieve the true text size before the draw occurs.

### TZxText
Reimplementation of FMX's `TText` control that implements `ISkTextSettings` instead of `ITextSettings`. There are 2 major differences when compared to `TText`:
1. The parent class is `TZxStyledControl` meaning it can be styled through the _StyleLookup_ property. The control expects the [TSkStyleTextObject](https://github.com/skia4delphi/skia4delphi/blob/main/Documents/LABEL.md#firemonkey-styles) in its style object and applies the text settings according to its _StyledSettings_ property. This way you can define and change your text settings in one place!
2. It contains a published _AutoSize_ property, which is self-explanatory. If you wish to retrieve the text size in runtime without having the _AutoSize_ property set to _True_, use the public property _ParagraphBounds_, which returns a _TRectF_ value.

### TZxTextControl
The FMX framework defines `TTextControl` and `TPresentedTextControl` classes, which serve as a base for all text controls, such as `TButton`, `TListBoxItem`, etc. They rely on their style objects to contain the `TText` control, whose _TextSettings_ can be modified in the Style Designer. Unfortunately, integrating those features into the mentioned base FMX classes is like getting blood from a stone, so ZX reimplemented the `TTextControl` into `TZxTextControl`, which utilizes `ISkTextSettings` instead of `ITextSettings`. The implementation is similar, except it contains the _AutoSize_ property. If true, the control will resize to the _TZxText.ParagraphBounds_ and any other objects (depending on their alignment and visibility) from its style resource.

### TZxCustomButton
This class implements the same functionality as FMX's `TCustomButton`, except its property _Images_ is a `TBaseImageList` instead of `TCustomImageList`, which allows you to assign both `TZxSvgBrushList` ([mentioned earlier](#TZxSvgBrushList)) and `TImageList`. If using the former, the style resource should contain the `TZxSvgGlyph` ([mentioned earlier](#TZxSvgGlyph)) component with _StyleName_ set to '_glyph_'.

#### TZxButton and TZxSpeedButton
These classes are the same as their counterparts, `TButton` and `TSpeedButton`.

## FMX style objects - revamped
The current FMX's approach to the application style relies on [```TBitmapLinks```](https://docwiki.embarcadero.com/Libraries/Athens/en/FMX.Styles.Objects.TBitmapLinks) that links to a part of a large image. Custom styles can be defined per platform, which allows the developer to bring the styles closer to the platform's native look. I won't go further into the details, as the [official documentation](https://docwiki.embarcadero.com/RADStudio/Athens/en/Customizing_FireMonkey_Applications_with_Styles) covers it well.

Looking at the currently most popular cross-platform applications, such as [Discord](https://discord.com/), [WhatsApp](https://www.whatsapp.com/), and [Slack](https://slack.com/), all share (almost) the same style across platforms. More applications tend to follow that path, and I am a fan as well: from the designer's standpoint, there is only one style that needs to be worked upon, and from the user's standpoint, I like to have the ability to switch platforms and still feel familiar with the same application. Keep in mind that I'm talking specifically about the application style and not the user interface.

The FMX framework introduces style object classes for defining the bitmap links. Their ancestor class is [`TCustomStyleObject`](https://docwiki.embarcadero.com/Libraries/Athens/en/FMX.Styles.Objects.TCustomStyleObject), which draws a bitmap on the canvas by retrieving the bitmap link from a virtual abstract function _GetCurrentLink_ and getting the actual bitmap from the _Source_, the large image I mentioned above. Every child class defines its own set of bitmap link published properties (e.g. [`TActiveStyleObject`](https://docwiki.embarcadero.com/Libraries/Athens/en/FMX.Styles.Objects.TActiveStyleObject) has _SourceLink_ and _ActiveLink_) that they return in the _GetCurrentLink_ function, depending on which one is active.

What I find troubling with this implementation is that the FMX has set the bitmap links and the image source as the base of their style object classes, and built upon that are the child classes functionalities. It is impossible to define any other link types (such as `TAlphaColor`, or since _skia4delphi_, `TSkSvgBrush`) and implement a custom drawing to the canvas. Because of that, ZX reimplements the style object classes so that the functionalities are defined first, and then the child classes can implement the drawing in any way they want.

An additional limitation of the bitmap links is the lack of animations. If you take a look at some the FMX's style objects implementation, you'll see that they use the [`TAnimation`](https://docwiki.embarcadero.com/Libraries/Athens/en/FMX.Ani.TAnimation) internally; but not for doing actual animations. `TAnimation`, besides its core functionality, provides two additional properties: _Trigger_ and _TriggerInverse_, which are used to decide when to start the animation ([learn more](https://docwiki.embarcadero.com/RADStudio/Athens/en/FireMonkey_Animation_Effects)). Some style objects use this, while the animation is set to never start, only to notify the handler that the trigger has occurred.

### TZxCustomActiveStyleObject
Style object similar to [`TActiveStyleObject`](https://docwiki.embarcadero.com/Libraries/Athens/en/FMX.Styles.Objects.TActiveStyleObject); it contains a published property _ActiveTrigger_ for defining the trigger type. Unlike its counterpart, it contains no implementation for handling the trigger (e.g. drawing a bitmap link). It also contains a public property _Duration_, for setting the animation duration.

#### TZxColorActiveStyleObject
A descendant of `TZxCustomActiveStyleObject` that draws a colored rectangle (fill color only) depending on the trigger state. When the trigger occurs, the color change is animated through interpolation. To set the colors, use the published properties _SourceColor_ and _ActiveColor_. The class also contains _RadiusX_ and _RadiusY_, allowing you to draw a round rectangle.

#### TZxAnimatedImageActiveStyleObject
Thanks to _skia4delphi_, we can display animated images through [`TSkAnimatedImage`](https://github.com/skia4delphi/skia4delphi/blob/main/Documents/ANIMATED-IMAGES.md). This class implements a `TSkAnimatedImage` whose animation starts when the trigger is executed. There are two possible states, depending on the boolean value of the _AniLoop_ property:
1. If set to false, the animation starts on the trigger and starts inversed on the inverse trigger, but does not loop, and
2. if set to true, the animation starts on the trigger in a loop and stops on the inverse trigger.
There are also additional properties for the image animation: _AniDelay_, _AniSource_, and _AniSpeed_.

### TZxCustomButtonStyleObject
This class implements the functionality of the `TButtonStyleObject` with the button trigger types (_Normal_, _Hot_, _Pressed_, _Focused_), but whose animations have a changeable duration through the published _Duration_ property.

#### TZxColorButtonStyleObject
A descendant of `TZxCustomButtonStyleObject` that draws a colored rectangle (fill color only) depending on the trigger state. When any trigger occurs, the animation interpolates the previous trigger color and the new trigger color. To set the trigger colors, use the published properties _NormalColor_, _HotColor_, _PressedColor_, or _FocusedColor_. The class also contains _RadiusX_ and _RadiusY_, allowing you to draw a round rectangle.

### TZxCustomTextButtonStyleObject
This class descends from `TZxCustomButtonStyleObject`, and is meant to be inherited. It contains a `TZxText` instance to apply animated changes. In the descendant, you should override the `OnTriggerProcess` method to implement custom behavior. See `TZxTextSettingsButtonStyleObject` for an example.

#### TZxTextSettingsButtonStyleObject
A descendant of `TZxCustomTextButtonStyleObject` that changes the text settings depending on the trigger state. When any trigger occurs, all text settings of that trigger are instantly applied (font, weight, decorations, etc.), and only the font color is animated through interpolation of the previous trigger color and the new trigger color. To set the text settings, use the published properties _NormalTextSettings_, _HotTextSettings_, _PressedTextSettings_, or _FocusedTextSettings_.

### TZxCustomSvgGlyphButtonStyleObject
This class descends from `TZxCustomButtonStyleObject`, and is meant to be inherited. It contains a `TZxSvgGlyph` instance to apply animated changes. In the descendant, you should override the `OnTriggerProcess` method to implement custom behavior. See `TZxColorOverrideSvgGlyphButtonStyleObject` for an example.

#### TZxColorOverrideSvgGlyphButtonStyleObject
A descendant of `TZxCustomSvgGlyphButtonStyleObject` that animates the change of `TZxSvgGlyph`.OverrideColor property on triggers.

# Adding default style for components 
While writing these components, I had trouble finding how to define a default style for a component that:
1. doesn't require overriding the _GetStyleObject_ method in every class to load the style from a resource, and
2. works in both runtime and design-time (without opening the unit in which the style is defined).

The current [documentation](https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Step_3_-_Add_Style-Resources_as_RCDATA_(Delphi)#Add_the_Style-Resources_as_RCDATA) doesn't satisfy the first request, and for the second one, to get the style to show up in runtime, the style resource has to be added to the application (at least that is the only solution I found). What bothered me is that the FMX controls have their default styles and do not load the same way as described in the existing documentation. In pursuit of achieving the same behavior, I realized that the styles are loaded in design-time similar to that in the runtime, except the loading of the [`TStyleBook`](https://docwiki.embarcadero.com/Libraries/Athens/en/FMX.Controls.TStyleBook) component. That gave me the idea to get the design-time's current `TStyleContainer` through [`TStyleManager`](https://docwiki.embarcadero.com/Libraries/Athens/en/FMX.Styles.TStyleManager)'s function `ActiveStyle`, and then add the custom control's default style to its children list. To implement this, ZX provides a `TZxStyleManager` class with the following class methods:
```delphi
class function AddStyles(const ADataModuleClass: TDataModuleClass): IZxStylesHolder; overload;
class function AddStyles(const AStyleContainer: TStyleContainer; const AClone: Boolean): IZxStylesHolder; overload;
class procedure RemoveStyles(const AStylesHodler: IZxStylesHolder);
```

_Note:_ The first _AddStyles_ procedure with the _ADataModuleClass_ parameter internally creates the data module instance, loops through its children, and for every `TStyleBook` instance does the same process as the second _AddStyles_ method. 

The `IZxStyleHolder` interface has no exposed methods or properties and is used only as a reference to the added styles which can be removed by calling the method _RemoveStyles_. The actual instance that implements the interface holds a list of the added styles, which the `TZxStyleManager` handles and uses for removing the styles from the global style container.

## Advantages and disadvantages
The benefits of this implementation are:
- no need for data resources,
- no need to override the _GetStyleObject_ method, and
- the styles are always visible, without needing to open the data module unit in which the style is defined.

Caveats to this implementation are yet to be found.

_WARNING:_ This implementation is not thoroughly tested on all platforms, so there is a possibility you may run into bugs or problems when using this approach. It has been tested with only one platform/collection defined, _Default_, as ZX's style approach is one-for-all. Feel free to report any issues or suggest improvements!

## How to use
There are 2 ways you can use the `TZxStyleManager`:
1. The simpler implementation includes calling _TZxStyleManager.AddStyles_ without a `IZxStylesHolder` instance, which means the `TZxStyleManager` will handle the removal of your registered styles.
2. Manually create a `TZxStylesHolder` instance and handle its lifetime. Call _TZxStyleManager.AddStyles_ with that instance; `TZxStyleManager` will put the registered styles inside it. To unregister the styles, call _TZxStyleManager.RemoveStyles_. This implementation allows you to add and remove different styles during run-time with an ease.

The simpler implementation steps:
1. Create a `TDataModule`, add a `TStyleBook`, and fill it with styles (you should also remove the global field that is used for registering the module to the _FMX.Forms.Application_ instance).
2. Add _Zx.StyleManager_ unit in the _uses_ section.
3. In the initialization section, call _TZxStyleManager.AddStyles_ with your data module class as the parameter.

The manual handling implementation steps:
1. Create a `TDataModule`, add a `TStyleBook`, and fill it with styles (you should also remove the global field that is used for registering the module to the _FMX.Forms.Application_ instance).
2. Add _Zx.StyleManager_ unit in the _uses_ section.
3. In the implementation section, declare a variable of type `IZxStylesHolder`.
4. In the initialization section, create a `TZxStylesHolder` instance and assign it to the previously declared variable.
5. In the initialization section, call _TZxStyleManager.AddStyles_ with your data module class as the first parameter, and your previously declared variable as the second parameter.
6. In the finalization section, call _TZxStyleManager.RemoveStyles_ with the previously declared variable as the parameter.
