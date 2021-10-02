package peote.text;

#if !macro
@:genericBuild(peote.text.FontProgram.FontProgramMacro.build("FontProgram"))
class FontProgram<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import peote.text.util.Macro;

class FontProgramMacro
{
	static public function build(name:String):ComplexType return Macro.build(name, buildClass);
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>):ComplexType
	{
		className += Macro.classNameExtension(styleName, styleModule);
		
		if ( Macro.isNotGenerated(className) )
		{
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			var glyphType = Glyph.GlyphMacro.buildClass("Glyph", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			var lineType  = Line.LineMacro.buildClass("Line", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			var pageLineType = PageLine.PageLineMacro.buildClass("PageLine", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			
			var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
			var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
			
			var charDataType:ComplexType;
			if (glyphStyleHasMeta.packed) {
				if (glyphStyleHasMeta.multiTexture && glyphStyleHasMeta.multiSlot) charDataType = macro: {unit:Int, slot:Int, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
				else if (glyphStyleHasMeta.multiTexture) charDataType = macro: {unit:Int, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
				else if (glyphStyleHasMeta.multiSlot) charDataType = macro: {slot:Int, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
				else charDataType = macro: {fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
			}
			else  {
				if (glyphStyleHasMeta.multiTexture && glyphStyleHasMeta.multiSlot) charDataType = macro: {unit:Int, slot:Int, min:Int, max:Int, height:Float, base:Float};
				else if (glyphStyleHasMeta.multiTexture) charDataType = macro: {unit:Int, min:Int, max:Int, height:Float, base:Float};
				else if (glyphStyleHasMeta.multiSlot) charDataType = macro: {slot:Int, min:Int, max:Int, height:Float, base:Float};
				else charDataType = macro: {min:Int, max:Int, height:Float, base:Float};
			}
			
			var c = macro
			
			// -------------------------------------------------------------------------------------------
			// -------------------------------------------------------------------------------------------

class $className extends peote.view.Program
{
	public var font:peote.text.Font<$styleType>;
	public var fontStyle:$styleType;
	
	public var isMasked(default, null) = false;
	var maskProgram:peote.view.Program;
	var maskBuffer:peote.view.Buffer<peote.text.MaskElement>;
	
	public var hasBackground(default, null) = false;
	var backgroundProgram:peote.view.Program;
	var backgroundBuffer:peote.view.Buffer<peote.text.BackgroundElement>;
	
	var _buffer:peote.view.Buffer<$glyphType>;
	
	public inline function new(font:peote.text.Font<$styleType>, fontStyle:$styleType, isMasked:Bool = false, hasBackground:Bool = false)
	{
		_buffer = new peote.view.Buffer<$glyphType>(1024,1024,true);
		super(_buffer);
		
		if (isMasked) enableMasking();
		if (hasBackground) enableBackground();

		setFont(font);
		setFontStyle(fontStyle);
	}
	
	override public function addToDisplay(display:peote.view.Display, ?atProgram:peote.view.Program, addBefore:Bool=false)
	{
		super.addToDisplay(display, atProgram, addBefore);
		if (isMasked) maskProgram.addToDisplay(display, this, true);
		if (hasBackground) backgroundProgram.addToDisplay(display, this, true);
	}
	
	override public function removeFromDisplay(display:peote.view.Display):Void
	{
		super.removeFromDisplay(display);
		if (isMasked) maskProgram.removeFromDisplay(display);
		if (hasBackground) backgroundProgram.removeFromDisplay(display);
	}
	
	// -----------------------------------------
	// ----------- Mask Program  ---------------
	// -----------------------------------------
	public inline function enableMasking() {
			isMasked = true;
			maskBuffer = new peote.view.Buffer<peote.text.MaskElement>(16, 16, true);
			maskProgram = new peote.view.Program(maskBuffer);
			maskProgram.mask = peote.view.Mask.DRAW;
			maskProgram.colorEnabled = false;
			mask = peote.view.Mask.USE;
			if (hasBackground) backgroundProgram.mask = peote.view.Mask.USE;
	}
	
	public inline function createMask(x:Int, y:Int, w:Int, h:Int, autoAdd = true):peote.text.MaskElement {
		var maskElement = new peote.text.MaskElement(x, y, w, h);
		if (autoAdd ) maskBuffer.addElement(maskElement);
		return maskElement;
	}
	
	public inline function createLineMask(line:$lineType, from:Null<Int> = null, to:Null<Int> = null, autoAdd = true):peote.text.MaskElement {		
		if (from != null && to != null && from > to) {
			var tmp = to;
			to = from;
			from = tmp;
		}
		if (from == null || from < line.visibleFrom) from = line.visibleFrom;		
		if (to == null || to > line.visibleTo - 1) to = line.visibleTo - 1;
		var w:Int = 0;
		var x:Int = 0;		
		if (from <= to) {
			x = Std.int( leftGlyphPos(line.getGlyph(from), getCharData(line.getGlyph(from).char)) );
			w = Std.int( rightGlyphPos(line.getGlyph(to), getCharData(line.getGlyph(to).char)) - x);
		}
		return createMask(x, Std.int(line.y), w, Std.int(line.height), autoAdd);
	}
	
	public inline function setLineMask(maskElement:peote.text.MaskElement, line:$lineType, from:Null<Int> = null, to:Null<Int> = null, autoUpdate = true):Void {
		if (from != null && to != null && from > to) {
			var tmp = to;
			to = from;
			from = tmp;
		}
		if (from == null || from < line.visibleFrom) from = line.visibleFrom;		
		if (to == null || to > line.visibleTo - 1) to = line.visibleTo - 1;
		if (from > to) maskElement.w = 0;
		else {
			maskElement.x = Std.int( lineGetPositionAtChar(line, from) );
			maskElement.y = Std.int( line.y );
			maskElement.w = Std.int( lineGetPositionAtChar(line, to + 1) - maskElement.x );		
			maskElement.h = Std.int( line.height );
		}
		if (autoUpdate) updateMask(maskElement);
	}

	public inline function addMask(maskElement:peote.text.MaskElement):Void {
		maskBuffer.addElement(maskElement);
	}
	
	public inline function updateMask(maskElement:peote.text.MaskElement):Void {
		maskBuffer.updateElement(maskElement);
	}
	
	public inline function removeMask(maskElement:peote.text.MaskElement):Void {
		maskBuffer.removeElement(maskElement);
	}
	
	// -----------------------------------------
	// -------- Background Program  ------------
	// -----------------------------------------
	public inline function enableBackground() {
		hasBackground = true;
		backgroundBuffer = new peote.view.Buffer<peote.text.BackgroundElement>(16, 16, true);
		backgroundProgram = new peote.view.Program(backgroundBuffer);
		if (isMasked) backgroundProgram.mask = peote.view.Mask.USE;
/*		${switch (glyphStyleHasField.zIndex) {
			case true: macro {}
			default: macro backgroundProgram.zIndexEnabled = false;
		}}
*/	
	}
		
	public inline function createBackground(x:Float, y:Float, w:Float, h:Float, z:Int, color:peote.view.Color, autoAdd = true):peote.text.BackgroundElement {
		var backgroundElement = new peote.text.BackgroundElement(x, y, w, h, z, color);
		if (autoAdd) backgroundBuffer.addElement(backgroundElement);
		return backgroundElement;
	}
	
	public inline function createLineBackground(line:$lineType, color:peote.view.Color, from:Null<Int> = null, to:Null<Int> = null, autoAdd = true):peote.text.BackgroundElement {		
		if (from != null && to != null && from > to) {
			var tmp = to;
			to = from;
			from = tmp;
		}
		if (from == null || from < line.visibleFrom) from = line.visibleFrom;
		if (to == null || to > line.visibleTo - 1) to = line.visibleTo - 1;
		var w:Float = 0;
		var x:Float = 0;
		var z:Int = 0;
		if (from <= to) {
			x = leftGlyphPos(line.getGlyph(from), getCharData(line.getGlyph(from).char));
			w = rightGlyphPos(line.getGlyph(to), getCharData(line.getGlyph(to).char)) - x;
			${switch (glyphStyleHasField.zIndex) {
				case true: switch (glyphStyleHasField.local_zIndex) {
					case true: macro z = line.getGlyph(from).zIndex;
					default: macro z = fontStyle.zIndex;
				}
				default: macro {}
			}}
		}
		return createBackground(x, line.y, w, line.height, z, color, autoAdd);
	}
	
	public inline function setLineBackground(backgroundElement:peote.text.BackgroundElement, line:$lineType, color:Null<peote.view.Color> = null, from:Null<Int> = null, to:Null<Int> = null, autoUpdate = true):Void {
		if (from != null && to != null && from > to) {
			var tmp = to;
			to = from;
			from = tmp;
		}
		if (from == null || from < line.visibleFrom) from = (line.visibleFrom>0) ? line.visibleFrom-1 : line.visibleFrom;
		if (to == null || to > line.visibleTo - 1) to = (line.visibleTo < line.length) ? line.visibleTo : line.visibleTo - 1;	
		if (from > to) backgroundElement.w = 0;
		else {
			backgroundElement.x = lineGetPositionAtChar(line, from);
			backgroundElement.y = line.y;
			backgroundElement.w = lineGetPositionAtChar(line, to+1) - backgroundElement.x;	
			backgroundElement.h = line.height;
			${switch (glyphStyleHasField.zIndex) {
				case true: switch (glyphStyleHasField.local_zIndex) {
					case true: macro backgroundElement.z = line.getGlyph(from).zIndex;
					default: macro backgroundElement.z = fontStyle.zIndex;
				}
				default: macro {}
			}}
		}
		if (color != null) backgroundElement.color = color;
		if (autoUpdate) updateBackground(backgroundElement);
	}
	
	public inline function addBackground(backgroundElement:peote.text.BackgroundElement):Void {
		backgroundBuffer.addElement(backgroundElement);
	}
	
	public inline function updateBackground(backgroundElement:peote.text.BackgroundElement):Void {
		backgroundBuffer.updateElement(backgroundElement);
	}
	
	public inline function removeBackground(backgroundElement:peote.text.BackgroundElement):Void {
		backgroundBuffer.removeElement(backgroundElement);
	}
	
	// -----------------------------------------
	// ---------------- Font  ------------------
	// -----------------------------------------
	public inline function setFont(font:Font<$styleType>):Void
	{
		this.font = font;
		autoUpdateTextures = false;

		${switch (glyphStyleHasMeta.multiTexture) {
			case true: macro setMultiTexture(font.textureCache.textures, "TEX");
			default: macro setTexture(font.textureCache, "TEX");
		}}
	}
	
	public inline function setFontStyle(fontStyle:$styleType):Void
	{
		this.fontStyle = fontStyle;
		
		alphaEnabled = true;		
		
		var color:String;
		${switch (glyphStyleHasField.local_color) {
			case true: macro color = "color";
			default: switch (glyphStyleHasField.color) {
				case true: macro color = Std.string(fontStyle.color.toGLSL());
				default: macro color = Std.string(font.config.color.toGLSL());
		}}}
		
		var bgColor:String;
		${switch (glyphStyleHasField.local_bgColor) {
			case true: macro bgColor = "bgColor";
			default: switch (glyphStyleHasField.bgColor) {
				case true: macro bgColor = Std.string(fontStyle.bgColor.toGLSL());
				default: macro bgColor = Std.string(font.config.bgColor.toGLSL());
		}}}
		
		// check distancefield-rendering
		if (font.config.distancefield) {
			// TODO: adjusting the weight needs texture-offset in setCharcode()
			var weight = "0.5";
			${switch (glyphStyleHasField.local_weight) {
				case true:  macro weight = "weight";
				default: switch (glyphStyleHasField.weight) {
					case true: macro weight = peote.view.utils.Util.toFloatString(fontStyle.weight);
					default: macro {}
				}
			}}
			
			var sharp = peote.view.utils.Util.toFloatString(0.5);
			
			${switch (glyphStyleHasField.local_bgColor) {
				case true: macro setColorFormula("mix(" + bgColor + "," + color + "," + "smoothstep( " + weight + " - " + sharp + " * fwidth(TEX.r), " + weight + " + " + sharp + " * fwidth(TEX.r), TEX.r))");
				default: switch (glyphStyleHasField.bgColor) {
					case true: macro {
						if (fontStyle.bgColor == 0) setColorFormula(color + " * smoothstep( " + weight + " - " + sharp + " * fwidth(TEX.r), " + weight + " + " + sharp + " * fwidth(TEX.r), TEX.r)");
						else {
							discardAtAlpha(null);
							setColorFormula("mix(" + bgColor + "," + color + "," + "smoothstep( " + weight + " - " + sharp + " * fwidth(TEX.r), " + weight + " + " + sharp + " * fwidth(TEX.r), TEX.r))");
						}
					}
					default: macro {
						if (font.config.bgColor == 0) setColorFormula(color + " * smoothstep( " + weight + " - " + sharp + " * fwidth(TEX.r), " + weight + " + " + sharp + " * fwidth(TEX.r), TEX.r)");
						else {
							discardAtAlpha(null);
							setColorFormula("mix(" + bgColor + "," + color + "," + "smoothstep( " + weight + " - " + sharp + " * fwidth(TEX.r), " + weight + " + " + sharp + " * fwidth(TEX.r), TEX.r))");
						}
					}
			}}}
						
		}
		else {
			// TODO: bold for no distancefields needs some more spice inside fragmentshader (access to neightboar pixels!)

			// TODO: dirty outline
/*						injectIntoFragmentShader(
			"
				float outline(float t, float threshold, float width)
				{
					return clamp(width - abs(threshold - t) / fwidth(t), 0.0, 1.0);
				}						
			");
			//setColorFormula("mix("+color+" * TEX.r, vec4(1.0,1.0,1.0,1.0), outline(TEX.r, 1.0, 5.0))");							
			//setColorFormula("mix("+color+" * TEX.r, "+color+" , outline(TEX.r, 1.0, 2.0))");							
			//setColorFormula(color + " * mix( TEX.r, 1.0, outline(TEX.r, 0.3, 1.0*uZoom) )");							
			//setColorFormula("mix("+color+"*TEX.r, vec4(1.0,1.0,0.0,1.0), outline(TEX.r, 0.0, 1.0*uZoom) )");							
*/						
			${switch (glyphStyleHasField.local_bgColor) {
				case true: macro setColorFormula("mix(" + bgColor + "," + color + "," + "TEX.r)");
				default: switch (glyphStyleHasField.bgColor) {
					case true: macro {
						if (fontStyle.bgColor == 0) setColorFormula(color + " * TEX.r");
						else {
							discardAtAlpha(null);
							setColorFormula("mix(" + bgColor + "," + color + "," + "TEX.r)");
						}
					}
					default: macro {
						if (font.config.bgColor == 0) setColorFormula(color + " * TEX.r");
						else {
							discardAtAlpha(null);
							setColorFormula("mix(" + bgColor + "," + color + "," + "TEX.r)");
						}
					}
			}}}
										
		}

		${switch (glyphStyleHasField.zIndex && !glyphStyleHasField.local_zIndex) {
			case true: macro setFormula("zIndex", peote.view.utils.Util.toFloatString(fontStyle.zIndex));
			default: macro {}
		}}
		
		${switch (glyphStyleHasField.rotation && !glyphStyleHasField.local_rotation) {
			case true: macro setFormula("rotation", peote.view.utils.Util.toFloatString(fontStyle.rotation));
			default: macro {}
		}}
		

		var tilt:String = "0.0";
		${switch (glyphStyleHasField.local_tilt) {
			case true:  macro tilt = "tilt";
			default: switch (glyphStyleHasField.tilt) {
				case true: macro tilt = peote.view.utils.Util.toFloatString(fontStyle.tilt);
				default: macro {}
			}
		}}
		
		
		${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- packed font -------
			{
				// tilting
				if (tilt != "0.0") setFormula("x", "x + (1.0-aPosition.y)*w*" + tilt);
			}
			default: macro // ------- simple font -------
			{
				// make width/height constant if global
				${switch (glyphStyleHasField.local_width) {
					case true: macro {}
					default: switch (glyphStyleHasField.width) {
						case true:
							macro setFormula("width", peote.view.utils.Util.toFloatString(fontStyle.width));
						default:
							macro setFormula("width", peote.view.utils.Util.toFloatString(font.config.width));
				}}}
				${switch (glyphStyleHasField.local_height) {
					case true: macro {}
					default: switch (glyphStyleHasField.height) {
						case true:
							macro setFormula("height", peote.view.utils.Util.toFloatString(fontStyle.height));
						default:
							macro setFormula("height", peote.view.utils.Util.toFloatString(font.config.height));
				}}}
				
				// mixing alpha while use of zIndex
				${switch (glyphStyleHasField.zIndex && !glyphStyleHasField.bgColor) {
					case true: macro { discardAtAlpha(0.5); }
					default: macro { }
				}}
				
				if (tilt != "" && tilt != "0.0") setFormula("x", "x + (1.0-aPosition.y)*width*" + tilt);
				
			}
			
		}}
		
		updateTextures();
	}
	
	// -------------------------------------------------------------------------------------------------
	// -------------------------------------------------------------------------------------------------
	// -------------------------------------------------------------------------------------------------
	
	// returns range, fontdata and metric in dependend of font-type
	inline function getCharData(charcode:Int):$charDataType
	{
		${switch (glyphStyleHasMeta.packed) {
			// ------- Gl3Font -------
			case true: 
				if (glyphStyleHasMeta.multiTexture && glyphStyleHasMeta.multiSlot) {
					macro {
						var range = font.getRange(charcode);
						if (range != null) {
							var metric = range.fontData.getMetric(charcode);
							if (metric == null) return null;
							else return {unit:range.unit, slot:range.slot, fontData:range.fontData, metric:metric};
						}
						else return null;
					}
				}
				else if (glyphStyleHasMeta.multiTexture) 
					macro {
						var range = font.getRange(charcode);
						if (range != null) {
							var metric = range.fontData.getMetric(charcode);
							if (metric == null) return null;
							else return {unit:range.unit, fontData:range.fontData, metric:metric};
						}
						else return null;
					}
				else if (glyphStyleHasMeta.multiSlot)
					macro {
						var range = font.getRange(charcode);
						if (range != null) {
							var metric = range.fontData.getMetric(charcode);
							if (metric == null) return null;
							else return {slot:range.slot, fontData:range.fontData, metric:metric};
						}
						else return null;
					}
				else macro {
						//var metric = font.getRange(charcode).getMetric(charcode);
						var range = font.getRange(charcode);
						var metric = range.getMetric(charcode);
						if (metric == null) return null;
						else return {fontData:range, metric:metric};
					}
			// ------- simple font -------
			default:macro return font.getRange(charcode);
		}}
	}
	
	// -------------------------------------------------
	
	inline function rightGlyphPos(glyph:$glyphType, charData:$charDataType):Float
	{
		${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro return glyph.x + (charData.metric.advance - charData.metric.left) * glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro return glyph.x + (charData.metric.advance - charData.metric.left) * fontStyle.width;
						default: macro return glyph.x + (charData.metric.advance - charData.metric.left) * font.config.width;
				}}}
			}
			default: macro // ------- simple font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro return glyph.x + glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro return glyph.x + fontStyle.width;
						default: macro return glyph.x + font.config.width;
				}}}
			}
		}}
	}
	
	inline function leftGlyphPos(glyph:$glyphType, charData:$charDataType):Float
	{
		${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro return glyph.x - (charData.metric.left) * glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro return glyph.x - (charData.metric.left) * fontStyle.width;
						default: macro return glyph.x - (charData.metric.left) * font.config.width;
				}}}
			}
			default: macro // ------- simple font -------
			{
				return glyph.x;
			}
		}}
		
	}
	
	inline function nextGlyphOffset(glyph:$glyphType, charData:$charDataType):Float
	{
		${switch (glyphStyleHasMeta.packed)
		{	case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro return charData.metric.advance * glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro return charData.metric.advance * fontStyle.width;
						default: macro return charData.metric.advance * font.config.width;
				}}}
			}
			default: macro // ------- simple font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro return glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro return fontStyle.width;
						default: macro return font.config.width;
				}}}
			}
		}}					
	}
	
	inline function letterSpace(glyph:$glyphType):Float
	{	
		${switch (glyphStyleHasField.local_letterSpace) {
			case true: macro return glyph.letterSpace;
			default: switch (glyphStyleHasField.letterSpace) {
				case true: macro return fontStyle.letterSpace;
				default: macro return 0.0;// font.config.letterSpace; // enable into FontConfig.hx
		}}}
	}
	
	inline function kerningSpaceOffset(prev_glyph:$glyphType, glyph:$glyphType, charData:$charDataType):Float
	{
		if (prev_glyph != null) {
			${switch (glyphStyleHasMeta.packed)
			{	case true: macro // ------- Gl3Font -------
				{	
					if (font.kerning) 
					{	//trace("kerning: ", prev_glyph.char, glyph.char, " -> " + charData.fontData.kerning[prev_glyph.char][glyph.char]);
						${switch (glyphStyleHasField.local_width) {
							case true: macro return charData.fontData.kerning[prev_glyph.char][glyph.char] * (glyph.width + prev_glyph.width)/2 + letterSpace(prev_glyph);
							default: switch (glyphStyleHasField.width) {
								case true: macro return charData.fontData.kerning[prev_glyph.char][glyph.char] * fontStyle.width + letterSpace(prev_glyph);
								default: macro return charData.fontData.kerning[prev_glyph.char][glyph.char] * font.config.width + letterSpace(prev_glyph);
						}}}
					}
					else return letterSpace(prev_glyph);
				}
				default: macro { // ------- simple font -------
					return letterSpace(prev_glyph);
				}
			}}					
		}
		else return 0.0;
	}
	
	// -------------------------------------------------

	inline function setPosition(glyph:$glyphType, charData:$charDataType, x:Float, y:Float)
	{					
		${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro glyph.x = x + charData.metric.left * glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro glyph.x = x + charData.metric.left * fontStyle.width;
						default: macro glyph.x = x + charData.metric.left * font.config.width;
				}}}
				${switch (glyphStyleHasField.local_height) {
					case true: macro glyph.y = y + (charData.fontData.base - charData.metric.top) * glyph.height;									
					default: switch (glyphStyleHasField.height) {
						case true: macro glyph.y = y + (charData.fontData.base - charData.metric.top) * fontStyle.height;
						default: macro glyph.y = y + (charData.fontData.base - charData.metric.top) * font.config.height;
				}}}							
			}
			default: macro // ------- simple font -------
			{
				glyph.x = x;
				glyph.y = y;
			}
		}}
	}
	
	inline function setSize(glyph:$glyphType, charData:$charDataType)
	{
		${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro glyph.w = charData.metric.width * glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro glyph.w = charData.metric.width * fontStyle.width;
						default: macro glyph.w = charData.metric.width * font.config.width;
				}}}
				${switch (glyphStyleHasField.local_height) {
					case true: macro glyph.h = charData.metric.height * glyph.height;
					default: switch (glyphStyleHasField.height) {
						case true: macro glyph.h = charData.metric.height * fontStyle.height;
						default: macro glyph.h = charData.metric.height * font.config.height;
				}}}
			}
			default: macro {} // ------- simple font have no metric
		}}
	}
	
	inline function setCharcode(glyph:$glyphType, charcode:Int, charData:$charDataType)
	{
		glyph.char = charcode;
		
		${switch (glyphStyleHasMeta.multiTexture) {
			case true: macro glyph.unit = charData.unit;
			default: macro {}
		}}
		${switch (glyphStyleHasMeta.multiSlot) {
			case true: macro glyph.slot = charData.slot;
			default: macro {}
		}}
		
		${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				// TODO: let glyphe-width also include metrics with tex-offsets on need
				//var weightOffset = (0.5 - glyph.weight) * 75;
				glyph.tx = charData.metric.u; // - weightOffset; // TODO: offsets for THICK weighted letters
				glyph.ty = charData.metric.v; // - weightOffset;
				glyph.tw = charData.metric.w; // + weightOffset + weightOffset;
				glyph.th = charData.metric.h; // + weightOffset + weightOffset;							
			}
			default: macro // ------- simple font -------
			{
				glyph.tile = charcode - charData.min;
			}
		}}
	
	}
	
	// -----------------------------------------
	// ---------------- Glyphes ----------------
	// -----------------------------------------
					
	public inline function createGlyph(charcode:Int, x:Float, y:Float, glyphStyle:$styleType = null):$glyphType {
		var charData = getCharData(charcode);
		if (charData != null) {
			var glyph = new peote.text.Glyph<$styleType>();
			glyphSetStyle(glyph, glyphStyle);
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			glyph.x = x;
			glyph.y = y;
			_buffer.addElement(glyph);
			return glyph;
		} else return null;
	}
	
	public inline function setGlyph(glyph:$glyphType, charcode:Int, x:Float, y:Float, glyphStyle:$styleType = null):Bool {
		var charData = getCharData(charcode);
		if (charData != null) {
			glyphSetStyle(glyph, glyphStyle);
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			glyph.x = x;
			glyph.y = y;
			_buffer.addElement(glyph);
			return true;
		} else return false;
	}
					
	public inline function addGlyph(glyph:$glyphType):Void {
			_buffer.addElement(glyph);
	}
					
	public inline function removeGlyph(glyph:$glyphType):Void {
		_buffer.removeElement(glyph);
	}
					
	public inline function updateGlyph(glyph:$glyphType):Void {
		_buffer.updateElement(glyph);
	}
	
	public inline function glyphSetStyle(glyph:$glyphType, glyphStyle:$styleType) {
		glyph.setStyle((glyphStyle != null) ? glyphStyle : fontStyle);
	}

	// sets position in depend of metrics-data
	// TODO: put on a given baseline
	public inline function glyphSetPosition(glyph:$glyphType, x:Float, y:Float) {
		var charData = getCharData(glyph.char);
		setPosition(glyph, charData, x, y);
	}

	public inline function glyphSetChar(glyph:$glyphType, charcode:Int):Bool
	{
		var charData = getCharData(charcode);
		if (charData != null) {
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			return true;
		} else return false;
	}

	public inline function numberOfGlyphes():Int return _buffer.length();

	
	
	// ---------------------------------------------
	// ---------------- PageLines ------------------
	// ---------------------------------------------

	public inline function setPageLine(pageLine:$pageLineType, line_size:Float, line_offset:Float, chars:String, x:Float=0, y:Float=0, glyphStyle:Null<$styleType> = null, defaultFontRange:Null<Int> = null):Bool
	{
		var line_max = x + line_size;
		pageLine.y = y;
		
		var x_start = x;
		x += line_offset;
		
		var glyph:$glyphType;
		var prev_glyph:$glyphType = null;
		var i = 0;
		var ret = true;
		var charData:$charDataType = null;
		
		var visibleFrom:Int = 0;
		var visibleTo:Int = 0;
		
		var old_length = pageLine.length;
		
		peote.text.util.StringUtils.iter(chars, function(charcode)
		{
			charData = getCharData(charcode);
			if (charData != null)
			{
				if (i >= old_length) { // append
					glyph = new peote.text.Glyph<$styleType>();
					pageLine.pushGlyph(glyph);
					glyphSetStyle(glyph, glyphStyle);
					setCharcode(glyph, charcode, charData);
					setSize(glyph, charData);
					
					x += kerningSpaceOffset(prev_glyph, glyph, charData);
					
					setPosition(glyph, charData, x, y);

					if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width;}} >= x_start) {														
						if (glyph.x < line_max) {
							_buffer.addElement(glyph);
							visibleTo ++;
						}
					}
					else {
						visibleFrom ++;
						visibleTo ++;
					}

					x += nextGlyphOffset(glyph, charData);
				}
				else { // set over
					glyph = pageLine.getGlyph(i);
					if (glyphStyle != null) glyphSetStyle(glyph, glyphStyle);
					setCharcode(glyph, charcode, charData);
					setSize(glyph, charData);
					
					x += kerningSpaceOffset(prev_glyph, glyph, charData);
					
					setPosition(glyph, charData, x, y);
			
					if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width;}} >= x_start) {														
						if (glyph.x < line_max) {
							if (i < pageLine.visibleFrom || i >= pageLine.visibleTo) _buffer.addElement(glyph);
							visibleTo ++;
						} else if (i < pageLine.visibleTo) _buffer.removeElement(glyph);
					}
					else {
						if (i >= pageLine.visibleFrom) _buffer.removeElement(glyph);
						visibleFrom ++;
						visibleTo ++;
					}
					
					x += nextGlyphOffset(glyph, charData);
				}
								
				// set line metric for the first char
				if (i == 0) {
					if (defaultFontRange == null) _setLineMetric(pageLine, glyph, charData);
					else {
						_setDefaultMetric(pageLine, defaultFontRange, glyphStyle);
						var y_offset = _baseLineOffset(pageLine, glyph, charData);
						glyph.y += y_offset;
						y += y_offset;
					}
				}
				
				prev_glyph = glyph;
				i++;
			}
			else ret = false;
		});
								
		if (i < old_length) {
			pageLineDeleteChars(pageLine, x_start, line_offset, line_size, i);
			for (j in Std.int(Math.max(i, pageLine.visibleFrom))...Std.int(Math.min(pageLine.length, pageLine.visibleTo))) {
				removeGlyph(pageLine.getGlyph(j));
			}
			pageLine.resize(i);							
		}
		
		// for an empty line set line metric to a default fontrange or to the first range into font
		if (i == 0) _setDefaultMetric(pageLine, (defaultFontRange == null) ? 0 : defaultFontRange, glyphStyle);
		
		
		pageLine.updateFrom = 0;
		pageLine.updateTo = i;
		
		pageLine.visibleFrom = visibleFrom;
		pageLine.visibleTo = visibleTo;
		
		pageLine.textSize = x - x_start - line_offset;

		return ret;		
	}	
	
	inline function _setDefaultMetric(pageLine:$pageLineType, defaultFontRange:Int, glyphStyle:Null<$styleType>) {
		var charCode = font.config.ranges[defaultFontRange].range.min;
		var charData = getCharData(charCode);
		var glyph = new peote.text.Glyph<$styleType>();
		glyphSetStyle(glyph, glyphStyle);
		setCharcode(glyph, charCode, charData);
		setSize(glyph, charData);
		_setLineMetric(pageLine, glyph, charData);
	}
	
	inline function _setLineMetric(pageLine:$pageLineType, glyph:$glyphType, charData:$charDataType) {
		if (glyph != null) {
			${switch (glyphStyleHasMeta.packed) {
				case true: macro {
					var h = ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
					pageLine.height = h * charData.fontData.height;
					pageLine.lineHeight = h * charData.fontData.lineHeight;
					pageLine.base = h * charData.fontData.base;
					//trace("line metric:", pageLine.lineHeight, pageLine.height, pageLine.base);
				}
				default: macro {
					var h = ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
					pageLine.height = h;
					pageLine.lineHeight = h * charData.height;
					pageLine.base = h * charData.base;
					//trace("line metric:", pageLine.lineHeight, pageLine.height, pageLine.base);
				}
			}}
		}
	}
	
	inline function _baseLineOffset(pageLine:$pageLineType, glyph:$glyphType, charData:$charDataType):Float {
		if (glyph != null) {
			${switch (glyphStyleHasMeta.packed) {
				case true: macro {
					return pageLine.base - charData.fontData.base * ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
				}
				default: macro {
					return pageLine.base - charData.base * ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
				}
			}}
		} else return 0;
	}
	
	// ----------- change Line Style ----------------
	
	public inline function pageLineSetStyle(pageLine:$pageLineType, line_x:Float, line_offset:Float, line_size:Float, glyphStyle:$styleType, from:UInt = 0, to:Null<UInt> = null):Float
	{
		if (to == null || to > pageLine.length) to = pageLine.length;
		
		// swapping
		if (to < from) { var tmp = to; to = from; from = tmp; }
		else if (from == to) to++;
		
		if (from < pageLine.updateFrom) pageLine.updateFrom = from;
		if (to > pageLine.updateTo) pageLine.updateTo = to;
		
		var prev_glyph:$glyphType = null;
		
		var x = line_x + line_offset;
		var y = pageLine.y;
		
		if (from > 0) {
			x = rightGlyphPos(pageLine.getGlyph(from - 1), getCharData(pageLine.getGlyph(from - 1).char));
			prev_glyph = pageLine.getGlyph(from - 1);
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(from), getCharData(pageLine.getGlyph(from - 1).char));
		}
		var x_start = x;
		
		// first
		pageLine.getGlyph(from).setStyle(glyphStyle);
		var charData = getCharData(pageLine.getGlyph(from).char);
		
		y += _baseLineOffset(pageLine, pageLine.getGlyph(from), charData);
		
		setPosition(pageLine.getGlyph(from), charData, x, y);
		x += nextGlyphOffset(pageLine.getGlyph(from), charData);
				
		prev_glyph = pageLine.getGlyph(from);
		
		for (i in from+1...to)
		{
			pageLine.getGlyph(i).setStyle(glyphStyle);
			charData = getCharData(pageLine.getGlyph(i).char);
			
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(i), charData);
			
			setPosition(pageLine.getGlyph(i), charData, x, y);
			x += nextGlyphOffset(pageLine.getGlyph(i), charData);
			prev_glyph = pageLine.getGlyph(i);
		}

		x_start = x - x_start;
		
		if (to < pageLine.length) // rest
		{
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(to), charData);
			
			var offset = x - leftGlyphPos(pageLine.getGlyph(to), getCharData(pageLine.getGlyph(to).char));
			if (offset != 0.0) {
				pageLine.updateTo = pageLine.length;
				_setLinePositionOffset(pageLine, line_x, line_size, offset, from, to, pageLine.length);
			} else _setLinePositionOffset(pageLine, line_x, line_size, offset, from, to, to);
		} else _setLinePositionOffset(pageLine, line_x, line_size, 0, from, to, to);
		
		return x_start;
	}
	
	
	// ----------- change Line Position, Size and Offset ----------------

	public inline function pageLineSetPosition(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, xNew:Float, yNew:Float, offset:Null<Float> = null)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		//if (offset != null) _setLinePositionOffsetFull(pageLine, line_x, line_size, offset - line_offset + xNew - line_x, yNew - pageLine.y);
		if (offset != null) _setLinePositionOffsetFull(pageLine, xNew, line_size, offset - line_offset + xNew - line_x, yNew - pageLine.y);
		else
			for (i in 0...pageLine.length) {
				pageLine.getGlyph(i).x += xNew - line_x;
				pageLine.getGlyph(i).y += yNew - pageLine.y;
			}
		pageLine.y = yNew;
	}
	
	public inline function pageLineSetXPosition(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, xNew:Float, offset:Null<Float> = null)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		//if (offset != null) _setLinePositionOffsetFull(pageLine, line_x, line_size, offset - line_offset + xNew - line_x, 0);
		if (offset != null) _setLinePositionOffsetFull(pageLine, xNew, line_size, offset - line_offset + xNew - line_x, 0);
		else for (i in 0...pageLine.updateTo) pageLine.getGlyph(i).x += xNew - line_x;
	}
	
	public inline function pageLineSetYPosition(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, yNew:Float, offset:Null<Float> = null)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		if (offset != null) _setLinePositionOffsetFull(pageLine, line_x, line_size, offset - line_offset, yNew - pageLine.y);
		else for (i in 0...pageLine.updateTo) pageLine.getGlyph(i).y += yNew - pageLine.y;
		pageLine.y = yNew;
	}	
	
	public inline function pageLineSetPositionSize(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, xNew:Float, yNew:Float, offset:Null<Float> = null)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		//if (offset != null) _setLinePositionOffsetFull(pageLine, line_x, line_size, offset - line_offset + xNew - line_x,  yNew - pageLine.y);
		if (offset != null) _setLinePositionOffsetFull(pageLine, xNew, line_size, offset - line_offset + xNew - line_x,  yNew - pageLine.y);
		//else _setLinePositionOffsetFull(pageLine, line_x, line_size, xNew - line_x, yNew - pageLine.y);		
		else _setLinePositionOffsetFull(pageLine, xNew, line_size, xNew - line_x, yNew - pageLine.y);		
		pageLine.y = yNew;
	}

	public inline function pageLineSetSize(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, offset:Null<Float> = null)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		if (offset != null) _setLinePositionOffsetFull(pageLine, line_x, line_size, offset - line_offset);
		else _setLinePositionOffsetFull(pageLine, line_x, line_size);
	}

	public inline function pageLineSetOffset(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, offset:Float)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;
		_setLinePositionOffsetFull(pageLine, line_x, line_size, offset - line_offset);
	}

	inline function _setLinePositionOffsetFull(pageLine:$pageLineType, line_x:Float, line_size:Float, deltaX:Null<Float> = null, deltaY:Null<Float> = null) 
	{
		var line_max = line_x + line_size;
		
		var visibleFrom = pageLine.visibleFrom;
		var visibleTo = pageLine.visibleTo;
			
		for (i in 0...pageLine.length)
		{
			if (deltaX != null) pageLine.getGlyph(i).x += deltaX;
			if (deltaY != null) pageLine.getGlyph(i).y += deltaY;

			// calc visible range
			if (pageLine.getGlyph(i).x + ${switch(glyphStyleHasMeta.packed) {case true: macro pageLine.getGlyph(i).w; default: macro pageLine.getGlyph(i).width; }} >= line_x)
			{	
				if (pageLine.getGlyph(i).x < line_max) {
					if (i < pageLine.visibleFrom || i >= pageLine.visibleTo) {
						_buffer.addElement(pageLine.getGlyph(i));
						if (visibleFrom > i) visibleFrom = i;
						if (visibleTo < i + 1) visibleTo = i + 1;
					}
				} 
				else {
					if (i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
					if (visibleTo > i) visibleTo = i;
				}
			}
			else {
				if (i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
				visibleFrom = i + 1;
			}			
		}
		
		pageLine.visibleFrom = visibleFrom;
		pageLine.visibleTo = visibleTo;		
	}

	inline function _setLinePositionOffset(pageLine:$pageLineType, line_x:Float, line_size:Float, deltaX:Float, from:Int, withDelta:Int, to:Int)
	{
		var line_max = line_x + line_size;
		var visibleFrom = pageLine.visibleFrom;
		var visibleTo = pageLine.visibleTo;

		for (i in from...to) {
			
			if (i >= withDelta) pageLine.getGlyph(i).x += deltaX;
			
			// calc visible range
			if (pageLine.getGlyph(i).x + ${switch(glyphStyleHasMeta.packed) {case true: macro pageLine.getGlyph(i).w; default: macro pageLine.getGlyph(i).width; }} >= line_x)
			{	
				if (pageLine.getGlyph(i).x < line_max) {
					if (i < pageLine.visibleFrom || i >= pageLine.visibleTo) {
						_buffer.addElement(pageLine.getGlyph(i));
						if (visibleFrom > i) visibleFrom = i;
						if (visibleTo < i + 1) visibleTo = i + 1;
					}
				} 
				else {
					if (i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
					if (visibleTo > i) visibleTo = i;
				}
			}
			else {
				if (i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
				visibleFrom = i + 1;
			}
		}
		
		pageLine.visibleFrom = visibleFrom;
		pageLine.visibleTo = visibleTo;
		
		pageLine.textSize += deltaX; 
	}
	
	
	// ------------ set chars  ---------------
	
	public inline function pageLineSetChar(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, charcode:Int, position:Int=0, glyphStyle:$styleType = null):Float
	{
		var charData = getCharData(charcode);
		if (charData != null)
		{			
			if (position < pageLine.updateFrom) pageLine.updateFrom = position;
			if (position + 1 > pageLine.updateTo) pageLine.updateTo = position + 1;
			
			var prev_glyph:$glyphType = null;
			
			var x = line_x + line_offset;
			var y = pageLine.y;
			
			if (position > 0) {
				x = rightGlyphPos(pageLine.getGlyph(position - 1), getCharData(pageLine.getGlyph(position - 1).char));
				prev_glyph = pageLine.getGlyph(position - 1);
			}
			var x_start = x;
			
			if (glyphStyle != null) {
				glyphSetStyle(pageLine.getGlyph(position), glyphStyle);
				y += _baseLineOffset(pageLine, pageLine.getGlyph(position), charData);
			}
			setCharcode(pageLine.getGlyph(position), charcode, charData);
			setSize(pageLine.getGlyph(position), charData);
			
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(position), charData);
			
			setPosition(pageLine.getGlyph(position), charData, x, y);
			
			x += nextGlyphOffset(pageLine.getGlyph(position), charData);
			
			x_start = x - x_start;
			
			if (position+1 < pageLine.length) // rest
			{	
				x += kerningSpaceOffset(pageLine.getGlyph(position), pageLine.getGlyph(position+1), charData);
				
				var offset = x - leftGlyphPos(pageLine.getGlyph(position+1), getCharData(pageLine.getGlyph(position+1).char));
				if (offset != 0.0) {
					pageLine.updateTo = pageLine.length;
					_setLinePositionOffset(pageLine, line_x, line_size, offset, position, position + 1, pageLine.length);
				} else _setLinePositionOffset(pageLine, line_x, line_size, offset, position, position + 1, position + 1);
			} else _setLinePositionOffset(pageLine, line_x, line_size, 0, position, position + 1, position + 1);
			
			return x_start;
		} 
		else return 0;					
	}
	
	public inline function pageLineSetChars(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, chars:String, position:Int=0, glyphStyle:$styleType = null):Float
	{
		var prev_glyph:$glyphType = null;
		var x = line_x + line_offset;
		var y = pageLine.y;
		
		if (position > 0) {
			x = rightGlyphPos(pageLine.getGlyph(position - 1), getCharData(pageLine.getGlyph(position - 1).char));
			prev_glyph = pageLine.getGlyph(position - 1);
		}
		var x_start = x;

		var i = position;
		var charData:$charDataType = null;
		
		peote.text.util.StringUtils.iter(chars, function(charcode)
		{
			if (i < pageLine.length) 
			{							
				charData = getCharData(charcode);
				if (charData != null)
				{
					if (glyphStyle != null) {
						glyphSetStyle(pageLine.getGlyph(i), glyphStyle);
						if (i == position) // first
						{					
							y += _baseLineOffset(pageLine, pageLine.getGlyph(i), charData);
						}
					}
					setCharcode(pageLine.getGlyph(i), charcode, charData);
					setSize(pageLine.getGlyph(i), charData);
					
					x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(i), charData);
					
					setPosition(pageLine.getGlyph(i), charData, x, y);
					x += nextGlyphOffset(pageLine.getGlyph(i), charData);
					prev_glyph = pageLine.getGlyph(i);
					i++;
				}
			}
			else {
				var offset = pageLineInsertChar(pageLine, line_x, line_size, line_offset, charcode, i, glyphStyle); // TODO: use append
				if (offset > 0) {
					x += offset;
					i++;
				}
			}
		});
		
		if (position < pageLine.updateFrom) pageLine.updateFrom = position;
		if (position + i > pageLine.updateTo) pageLine.updateTo = Std.int(Math.min(position + i, pageLine.length));
		
		x_start = x - x_start;
		
		if (i < pageLine.length) // rest
		{
			x += kerningSpaceOffset(pageLine.getGlyph(i-1), pageLine.getGlyph(i), charData);
			
			var offset = x - leftGlyphPos(pageLine.getGlyph(i), getCharData(pageLine.getGlyph(i).char));
			if (offset != 0.0) {
				pageLine.updateTo = pageLine.length;
				_setLinePositionOffset(pageLine, line_x, line_size, offset, position, i, pageLine.length);
			} else _setLinePositionOffset(pageLine, line_x, line_size, offset, position, i, i);
		} else _setLinePositionOffset(pageLine, line_x, line_size, 0, position, i, i);
	
		return x_start;
	}
	
		
	// ------------- inserting chars ---------------------
	
	public inline function pageLineInsertChar(pageLine:$pageLineType, line_x:Float, line_size:Float, line_offset:Float, charcode:Int, position, glyphStyle:$styleType = null):Float
	{
		var charData = getCharData(charcode);
		if (charData != null)
		{
			var prev_glyph:$glyphType = null;
			
			var x = line_x + line_offset;
			var y = pageLine.y;
			
			if (position > 0) {
				x = rightGlyphPos(pageLine.getGlyph(position - 1), getCharData(pageLine.getGlyph(position - 1).char));
				prev_glyph = pageLine.getGlyph(position - 1);
			}
			var x_start = x;
			
			var glyph = new peote.text.Glyph<$styleType>();
			
			glyphSetStyle(glyph, glyphStyle);
			
			y += _baseLineOffset(pageLine, glyph, charData);
			
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			
			x += kerningSpaceOffset(prev_glyph, glyph, charData);
			
			setPosition(glyph, charData, x, y);						
			
			x += nextGlyphOffset(glyph, charData);
			
			if (position < pageLine.length) {				
				if (position < pageLine.updateFrom) pageLine.updateFrom = position+1;
				pageLine.updateTo = pageLine.length + 1;
				if (position == 0) x += kerningSpaceOffset(glyph, pageLine.getGlyph(position+1), charData);				
				_setLinePositionOffset(pageLine, line_x, line_size, x - x_start, position, position, pageLine.length);
			}
			else pageLine.textSize += x - x_start;
			
			pageLine.insertGlyph(position, glyph);
			
			if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width; }} >= line_x)
			{
				if (glyph.x < line_x + line_size) {
					_buffer.addElement(glyph);
					pageLine.visibleTo++;
				}
			} 
			else {
				pageLine.visibleFrom++;
				pageLine.visibleTo++;
			}
			
			return x - x_start;
		}
		else return 0;
	}
		
	public inline function pageLineInsertChars(pageLine:$pageLineType, x:Float, line_size:Float, offset:Float, chars:String, position:Int, glyphStyle:$styleType = null):Float 
	{					
		var prev_glyph:$glyphType = null;
		var line_x = x;
		var y = pageLine.y;
		
		if (position > 0) {
			x = rightGlyphPos(pageLine.getGlyph(position - 1), getCharData(pageLine.getGlyph(position - 1).char));
			prev_glyph = pageLine.getGlyph(position - 1);
			offset = 0;
		}
		
		var rest = pageLine.splice(position, pageLine.length - position);
		
		if (rest.length > 0) {
			var oldFrom = pageLine.visibleFrom - pageLine.length;
			var oldTo = pageLine.visibleTo - pageLine.length;
			if (pageLine.visibleFrom > pageLine.length) pageLine.visibleFrom = pageLine.length;
			if (pageLine.visibleTo > pageLine.length) pageLine.visibleTo = pageLine.length;

			var deltaX = _lineAppend(pageLine, line_size, offset, chars, x, y, prev_glyph, glyphStyle);

			if (position == 0) {
				var kerningSpace = kerningSpaceOffset(pageLine.getGlyph(pageLine.length-1), rest[0], getCharData(rest[0].char));
				deltaX += kerningSpace;
				pageLine.textSize += kerningSpace;
			}
			
			if (deltaX != 0.0) // TODO
			{
				if (pageLine.length < pageLine.updateFrom) pageLine.updateFrom = pageLine.length;
				
				var line_max = line_x + line_size;				
				for (i in 0...rest.length) {
					rest[i].x += deltaX;
					
					if (rest[i].x + ${switch(glyphStyleHasMeta.packed) {case true: macro rest[i].w; default: macro rest[i].width; }} >= line_x)
					{	
						if (rest[i].x < line_max) {
							if (i < oldFrom || i >= oldTo) {
								_buffer.addElement(rest[i]);
							}
							pageLine.visibleTo++;
						} else if (i >= oldFrom && i < oldTo) {
							_buffer.removeElement(rest[i]);
						}
					}
					else {
						if (i >= oldFrom && i < oldTo) {
							_buffer.removeElement(rest[i]);
						}
						pageLine.visibleFrom++;
						pageLine.visibleTo++;
					}
				}
					
				pageLine.append(rest);

				pageLine.updateTo = pageLine.length;
			} 
			else {
				pageLine.visibleFrom = oldFrom + pageLine.length;
				pageLine.visibleTo = oldTo + pageLine.length;							
				pageLine.append(rest);
			}
			return deltaX;
		}
		else return _lineAppend(pageLine, line_size, offset, chars, x, y, prev_glyph, glyphStyle);
	}
		

	// ------------- appending chars ---------------------
	
	public inline function _lineAppend(pageLine:$pageLineType, line_size:Float, offset:Float, chars:String, x:Float, y:Float, prev_glyph:peote.text.Glyph<$styleType>, glyphStyle:$styleType):Float
	{
		var first = true;
		var glyph:$glyphType = null;
		var charData:$charDataType = null;
		
		var line_x = x;
		
		x += offset;
		var x_start = x;
				
		var line_max = line_x + line_size;		
		
		peote.text.util.StringUtils.iter(chars, function(charcode)
		{
			charData = getCharData(charcode);
			if (charData != null)
			{
				glyph = new peote.text.Glyph<$styleType>();
				pageLine.pushGlyph(glyph);
				glyphSetStyle(glyph, glyphStyle);

				if (first) {
					first = false;
					y += _baseLineOffset(pageLine, glyph, charData);
				}
				setCharcode(glyph, charcode, charData);
				setSize(glyph, charData);
				
				x += kerningSpaceOffset(prev_glyph, glyph, charData);
				
				setPosition(glyph, charData, x, y);
				
				if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width;}} >= line_x)  {
					if (glyph.x < line_max)	{
						_buffer.addElement(glyph);
						pageLine.visibleTo ++;
					}
				}
				else {
					pageLine.visibleFrom ++;
					pageLine.visibleTo ++;
				}

				x += nextGlyphOffset(glyph, charData);

				prev_glyph = glyph;
			}
		});

		pageLine.textSize += x - x_start;
		
		return x - x_start;
	}
	
	
	// ------------- deleting chars ---------------------	

	public inline function pageLineDeleteChar(pageLine:$pageLineType, line_x:Float, line_offset:Float, line_size:Float, position:Int = 0):Float
	{	
		if (position >= pageLine.visibleFrom && position < pageLine.visibleTo) {
			removeGlyph(pageLine.getGlyph(position));
		}
		
		var offset = _pageLineDeleteCharsOffset(pageLine, line_x, line_offset, line_size, position, position + 1);
		
		if (position < pageLine.visibleFrom) {
			pageLine.visibleFrom--; pageLine.visibleTo--;
		} 
		else if (position < pageLine.visibleTo) {
			pageLine.visibleTo--;
		}

		pageLine.splice(position, 1);
		
		return offset;
	}
	
	public inline function pageLineCutChars(pageLine:$pageLineType, line_x:Float, line_offset:Float, line_size:Float, from:Int = 0, to:Null<Int> = null):String
	{
		if (to == null) to = pageLine.length;
		var cut = "";
		for (i in ((from < pageLine.visibleFrom) ? pageLine.visibleFrom : from)...((to < pageLine.visibleTo) ? to : pageLine.visibleTo)) {
			cut += String.fromCharCode(pageLine.getGlyph(i).char);
			removeGlyph(pageLine.getGlyph(i));
		}
		_pageLineDeleteChars(pageLine, line_x, line_offset, line_size, from, to);
		return cut;
	}
	
	public inline function pageLineGetChars(pageLine:$pageLineType, from:Int = 0, to:Null<Int> = null):String
	{
		if (to == null) to = pageLine.length;
		var chars:String = "";
		for (glyph in pageLine.glyphes) {
			chars += String.fromCharCode(glyph.char);
		}
		return chars;
	}
	
	public inline function pageLineDeleteChars(pageLine:$pageLineType, line_x:Float, line_offset:Float, line_size:Float, from:Int = 0, to:Null<Int> = null):Float
	{
		if (to == null) to = pageLine.length;
		for (i in ((from < pageLine.visibleFrom) ? pageLine.visibleFrom : from)...((to < pageLine.visibleTo) ? to : pageLine.visibleTo)) {
			removeGlyph(pageLine.getGlyph(i));
		}
		return _pageLineDeleteChars(pageLine, line_x, line_offset, line_size, from, to);
	}
	
	inline function _pageLineDeleteChars(pageLine:$pageLineType, line_x:Float, line_offset:Float, line_size:Float, from:Int, to:Int):Float
	{
		var offset = _pageLineDeleteCharsOffset(pageLine, line_x, line_offset, line_size, from, to);
		
		if (from < pageLine.visibleFrom) {
			pageLine.visibleFrom = (to < pageLine.visibleFrom) ? pageLine.visibleFrom - to + from : from;
			pageLine.visibleTo = (to < pageLine.visibleTo) ? pageLine.visibleTo - to + from : from;
		}
		else if (from < pageLine.visibleTo) {
			pageLine.visibleTo = (to < pageLine.visibleTo) ? pageLine.visibleTo - to + from : from;
		}
		
		pageLine.splice(from, to - from);
		
		return offset;
	}
	
	inline function _pageLineDeleteCharsOffset(pageLine:$pageLineType, line_x:Float, line_offset:Float, line_size:Float, from:Int, to:Int):Float
	{
		var offset:Float = 0.0; 
		if (to < pageLine.length) 
		{
			var charData = getCharData(pageLine.getGlyph(to).char);
			if (from == 0) {
				offset = line_x + line_offset - leftGlyphPos(pageLine.getGlyph(to), charData);
			}
			else {
				offset = rightGlyphPos(pageLine.getGlyph(from - 1), getCharData(pageLine.getGlyph(from - 1).char)) - leftGlyphPos(pageLine.getGlyph(to), charData);
				offset += kerningSpaceOffset(pageLine.getGlyph(from-1), pageLine.getGlyph(to), charData);
			}
			
			if (pageLine.updateFrom > from) pageLine.updateFrom = from;
			pageLine.updateTo = pageLine.length - to + from;
			
			_setLinePositionOffset(pageLine, line_x, line_size, offset, to, to, pageLine.length);
		}
		else 
		{
			// delete from end
			if ( pageLine.updateFrom >= pageLine.length - to + from ) {
				pageLine.updateFrom = 0x1000000;
				pageLine.updateTo = 0;
			}
			else if ( pageLine.updateTo > pageLine.length - to + from) {
				pageLine.updateTo = pageLine.length - to + from;
			}
			
			if (from != 0)
				offset = rightGlyphPos(pageLine.getGlyph(from - 1), getCharData(pageLine.getGlyph(from - 1).char)) - (line_x + line_offset + pageLine.textSize);
			else offset = -pageLine.textSize;

			pageLine.textSize += offset;
		}
		return offset;
	}
	
	
	public inline function updatePageLine(pageLine:$pageLineType, from:Null<Int> = null, to:Null<Int> = null)
	{
		if (from != null) pageLine.updateFrom = from;
		if (to != null) pageLine.updateTo = to;
		
		//trace("visibleFrom: " + pageLine.visibleFrom+ "-" +pageLine.visibleTo);
		//trace("updateFrom : " +  pageLine.updateFrom + "-" +pageLine.updateTo);
		
		if (pageLine.updateTo > 0 )
		{
			if (pageLine.visibleFrom > pageLine.updateFrom) pageLine.updateFrom = pageLine.visibleFrom;
			if (pageLine.visibleTo < pageLine.updateTo) pageLine.updateTo = pageLine.visibleTo;
			//trace("update from " + pageLine.updateFrom + " to " +pageLine.updateTo);
			
			for (i in pageLine.updateFrom...pageLine.updateTo) updateGlyph(pageLine.getGlyph(i));

			pageLine.updateFrom = 0x1000000;
			pageLine.updateTo = 0;
		} //else trace("nothing to update");
	}
	
	
	
	// -----------------------------------------
	// ---------------- Lines ------------------
	// -----------------------------------------
	
	// TODO: storing all chars thats not includet into the font by editing line
	public var unrecognizedChars:String = "";
	
	
	/**
		Creates a new Line and returns it. The new created Line is displayed automatically.
		@param chars String that contains the chars (newlines have no effect)
		@param x horizontal position of the upper left pixel of the line, is 0 by default
		@param y vertical position of the upper left pixel of the line, is 0 by default
		@param size (optional) limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param glyphStyle (optional) GlyphStyle of the line, by default it is using the default FontStyle of the FontProgram 
		@param defaultFontRange (optional) unicode range of the Font where to fetch the line-metric from (by default it's using the metric from the range of the first letter)
	**/
	public inline function createLine(chars:String, x:Float=0, y:Float=0, size:Null<Float> = null, offset:Null<Float> = null, glyphStyle:Null<$styleType> = null, defaultFontRange:Null<Int> = null):$lineType
	{
		var line = new peote.text.Line<$styleType>();
		setLine(line, chars, x, y, size, offset, glyphStyle, defaultFontRange);
		return line;
	}
	
	/**
		Add the line to FontProgram to display it.
		@param line the Line instance
	**/
	public inline function addLine(line:$lineType):Void
	{
		for (i in line.visibleFrom...line.visibleTo) addGlyph(line.getGlyph(i));
	}
	
	/**
		Removes the line from FontProgram to not display it anymore.
		@param line the Line instance
	**/
	public inline function removeLine(line:$lineType)
	{
		for (i in line.visibleFrom...line.visibleTo) removeGlyph(line.getGlyph(i));
	}
	
	/**
		Changing all chars of an existing Line. (can be faster than creating a new line)
		@param line the Line instance
		@param chars String that contains the chars (newlines have no effect)
		@param x horizontal position of the upper left pixel of the line, is 0 by default
		@param y vertical position of the upper left pixel of the line, is 0 by default
		@param size (optional) limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param glyphStyle (optional) GlyphStyle of the line, by default it is using the default FontStyle of the FontProgram 
		@param defaultFontRange (optional) unicode range of the Font where to fetch the line-metric from (by default it's using the metric from the range of the first letter)
	**/
	public inline function setLine(line:$lineType, chars:String, x:Float=0, y:Float=0, size:Null<Float> = null, offset:Null<Float> = null, glyphStyle:Null<$styleType> = null, defaultFontRange:Null<Int> = null):Bool
	{
		line.x = x;
		if (size != null) line.size = size;
		if (offset != null) line.offset = offset;		
		return setPageLine(line.pageLine, line.size, line.offset, chars, x, y, glyphStyle, defaultFontRange);
	}
	
	/**
		Changing the style of glyphes in an existing Line. Needs updateLine() after to get effect.
		@param line Line instance
		@param glyphStyle new GlyphStyle
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
	**/
	public inline function lineSetStyle(line:$lineType, glyphStyle:$styleType, from:UInt = 0, to:Null<UInt> = null):Float
	{
		return pageLineSetStyle(line.pageLine, line.x, line.offset, line.size, glyphStyle, from, to);
	}
	
	/**
		Set the position of a Line. Needs updateLine() after to get effect.
		@param line Line instance
		@param x horizontal position of the upper left pixel of the line
		@param y vertical position of the upper left pixel of the line
		@param offset (optional) how much pixels the line is shifted inside it's visible range
	**/
	public inline function lineSetPosition(line:$lineType, x:Float, y:Float, offset:Null<Float> = null)
	{
		pageLineSetPosition(line.pageLine, line.x, line.size, line.offset, x, y, offset);
		line.x = x;
		if (offset != null) line.offset = offset;
	}
	
	/**
		Set the x position of a Line. Needs updateLine() after to get effect.
		@param line Line instance
		@param x horizontal position of the upper left pixel of the line
		@param offset (optional) how much pixels the line is shifted inside it's visible range
	**/
	public inline function lineSetXPosition(line:$lineType, x:Float, offset:Null<Float> = null)
	{
		pageLineSetXPosition(line.pageLine, line.x, line.size, line.offset, x, offset);
		line.x = x;
		if (offset != null) line.offset = offset;
	}
	
	/**
		Set the y position of a Line. Needs updateLine() after to get effect.
		@param line Line instance
		@param y vertical position of the upper left pixel of the line
		@param offset (optional) how much pixels the line is shifted inside it's visible range
	**/
	public inline function lineSetYPosition(line:$lineType, y:Float, offset:Null<Float> = null)
	{
		pageLineSetYPosition(line.pageLine, line.x, line.size, line.offset, y, offset);
		if (offset != null) line.offset = offset;
	}
	
	/**
		Set the position and size of a Line. Needs updateLine() after to get effect.
		@param line Line instance
		@param x horizontal position of the upper left pixel of the line
		@param y vertical position of the upper left pixel of the line
		@param size limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
	**/
	public inline function lineSetPositionSize(line:$lineType, x:Float, y:Float, size:Float, offset:Null<Float> = null)
	{
		pageLineSetPositionSize(line.pageLine, line.x, size, line.offset, x, y, offset);
		line.x = x;
		line.size = size;
		if (offset != null) line.offset = offset;
	}
		
	/**
		Set the size of a Line. Needs updateLine() after to get effect.
		@param line Line instance
		@param size limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
	**/
	public inline function lineSetSize(line:$lineType, size:Float, offset:Null<Float> = null)
	{
		pageLineSetSize(line.pageLine, line.x, size, line.offset, offset);
		line.size = size;
		if (offset != null) line.offset = offset;
	}
		
	/**
		Set the offset of how much the Line is shifted. Needs updateLine() after to get effect.
		@param line Line instance where to change the style
		@param offset how much pixels the line is shifted inside it's visible range
	**/
	public inline function lineSetOffset(line:$lineType, offset:Float)
	{
		pageLineSetOffset(line.pageLine, line.x, line.size, line.offset, offset);
		line.offset = offset;
	}

	/**
		Changing a char inside of a Line. Needs updateLine() after to get effect.
		@param line the Line instance
		@param charcode the unicode number of the char (newline have no effect)
		@param position where to change the char, is 0 by default (first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
	**/
	public inline function lineSetChar(line:$lineType, charcode:Int, position:Int = 0, glyphStyle:$styleType = null):Float
	{
		return pageLineSetChar(line.pageLine, line.x, line.size, line.offset, charcode, position, glyphStyle);
	}
	
	/**
		Changing the chars inside of a Line. Needs updateLine() after to get effect.
		@param line the Line instance
		@param chars String that contains the letters (newlines have no effect)
		@param position where to change, is 0 by default (first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
	**/
	public inline function lineSetChars(line:$lineType, chars:String, position:Int = 0, glyphStyle:$styleType = null):Float
	{
		return pageLineSetChars(line.pageLine, line.x, line.size, line.offset, chars, position, glyphStyle);		
	}
	
	/**
		Insert a new char into a Line. If it's not inserted at end of line it needs updateLine() after to get effect.
		@param line the Line instance
		@param charcode the unicode number of the new char (newline have no effect)
		@param position where to insert, is 0 by default (before first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
	**/
	public inline function lineInsertChar(line:$lineType, charcode:Int, position:Int = 0, glyphStyle:$styleType = null):Float
	{		
		return pageLineInsertChar(line.pageLine, line.x, line.size, line.offset, charcode, position, glyphStyle);
	}
	
	/**
		Insert new chars into a Line. If it's not inserted at end of line it needs updateLine() after to get effect.
		@param line the Line instance
		@param chars String that contains the new letters (newlines have no effect)
		@param position where to insert, is 0 by default (before first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
	**/
	public inline function lineInsertChars(line:$lineType, chars:String, position:Int = 0, glyphStyle:$styleType = null):Float 
	{		
		return pageLineInsertChars(line.pageLine, line.x, line.size, line.offset, chars, position, glyphStyle);
	}
	
	/**
		Append new chars at end of a Line.
		@param line the Line instance
		@param chars String that contains the new chars (newlines have no effect)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
	**/
	public inline function lineAppendChars(line:$lineType, chars:String, glyphStyle:$styleType = null):Float 
	{		
		if (line.length > 0)
			return _lineAppend(line.pageLine, line.size, 0, chars, rightGlyphPos(line.getGlyph(line.length - 1), getCharData(line.getGlyph(line.length - 1).char)), line.y, line.getGlyph(line.length - 1), glyphStyle);
		else return _lineAppend(line.pageLine, line.size, line.offset, chars, line.x, line.y, null, glyphStyle);
	}
	
	/**
		Delete a char from a Line and returns the offset of how much the line was shrinked.
		If it's not the last char into line it needs updateLine() after to get effect.
		@param line the Line instance
		@param position where to delete, is 0 by default (first char into line)
	**/
	public inline function lineDeleteChar(line:$lineType, position:Int = 0):Float
	{
		return pageLineDeleteChar(line.pageLine, line.x, line.offset, line.size, position);
	}
	
	/**
		Delete chars from a Line and returns the offset of how much the line was shrinked.
		If it's not the last chars into line it needs updateLine() after to get effect.
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
	**/
	public inline function lineDeleteChars(line:$lineType, from:Int = 0, to:Null<Int> = null):Float
	{
		return pageLineDeleteChars(line.pageLine, line.x, line.offset, line.size, from, to);
	}
	
	/**
		Delete chars from a Line and returns it as a String. If it's not the last chars it needs updateLine() after to get effect.
		@param line the Line instance
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
	**/
	public inline function lineCutChars(line:$lineType, from:Int = 0, to:Null<Int> = null):String
	{
		return pageLineCutChars(line.pageLine, line.x, line.offset, line.size, from, to);
	}
	
	/**
		Returns the chars from a Line as a String.
		@param line the Line instance
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
	**/
	public inline function lineGetChars(line:$lineType, from:Int = 0, to:Null<Int> = null):String
	{
		return pageLineGetChars(line.pageLine, from, to);
	}
	
	/**
		Updates a Line to apply the changes by one or more of the following functions:
		lineSetStyle(), lineSetPosition(), lineSetXPosition(), lineSetYPosition(), lineSetPositionSize(), lineSetSize(), lineSetOffset(),
		lineSetChar(), lineSetChars(), lineInsertChar(), lineInsertChars(), lineDeleteChar(), lineDeleteChars(), lineCutChars().
		Only chars that are into the visible area will be updated if the line is shifted by offset or limited by size.
		@param line the Line instance
		@param from position of the first char into range, by default this is set by the functions that was changing the line
		@param to position after the last char into range, by default this is set by the functions that was changing the line
	**/
	public inline function updateLine(line:$lineType, from:Null<Int> = null, to:Null<Int> = null)
	{
		 updatePageLine(line.pageLine, from, to);
	}
	
	/**
		Returns the x pixel-value of the middle position between a char and its previous char into a line.
		This function can be used to calculate a cursor-position.
		@param line the Line instance
		@param position index of the char into the line (0 returns the position before the first char)
	**/
	public inline function lineGetPositionAtChar(line:$lineType, position:Int):Float
	{
		if (position == 0) return line.x + line.offset;
		else if (position < line.length) {
			var chardata = getCharData(line.getGlyph(position).char);
			return (rightGlyphPos(line.getGlyph(position - 1), chardata) + leftGlyphPos(line.getGlyph(position), chardata)) / 2;
		} else return rightGlyphPos(line.getGlyph(line.length-1), getCharData(line.getGlyph(line.length-1).char));
	}
					
	/**
		Returns the index of the nearest char at a given x pixel-value.
		This function can be used to pick a char by mouse-position.
		@param line the Line instance
		@param xPosition x pixel-value at where to pick the nearest char
	**/
	public inline function lineGetCharAtPosition(line:$lineType, xPosition:Float):Int
	{
		if (xPosition <= line.x) return 0;
		else if (xPosition >= line.x + line.size) return line.visibleTo;
		else 
		{
			${switch (glyphStyleHasMeta.packed || glyphStyleHasField.local_width || glyphStyleHasField.local_letterSpace)
			{
				case true: macro
				{
					// TODO: binary search to optimze
					var i:Int = line.visibleFrom;
					while (i < line.visibleTo && xPosition > line.getGlyph(i).x) i++;
					if (i == 0) return 0;
					var chardata = getCharData(line.getGlyph(i - 1).char);
					if ( xPosition < (leftGlyphPos(line.getGlyph(i - 1), chardata) + rightGlyphPos(line.getGlyph(i - 1), chardata)) / 2)
						return i-1;
					else return i;
				}
				default: switch (glyphStyleHasField.width) {
					case true: macro return Math.round((xPosition - line.x - line.offset + letterSpace(null)/2)/(fontStyle.width + letterSpace(null)));
					default: macro return Math.round((xPosition - line.x - line.offset + letterSpace(null)/2)/(font.config.width + letterSpace(null)));
				}
			}}
		}
	}
		

	// T O D O
	
	// -----------------------------------------
	// ---------------- Pages ------------------
	// -----------------------------------------

	public inline function createPage(chars:String, x:Float=0, y:Float=0, glyphStyle:Null<$styleType> = null):peote.text.Page<$styleType>
	{
		var page = new peote.text.Page<$styleType>();
		if (setPage(page, chars, x, y, glyphStyle)) return page else return null;
	}
	
	public inline function addPage(page:Page<$styleType>)
	{
		//for (i in page.visibleFrom...page.visibleTo) addLine(page.getLine(i));
	}
	
	public inline function removePage(page:Page<$styleType>)
	{
		//for (i in page.visibleFrom...page.visibleTo) removeLine(page.getLine(i));
	}
	
	var regLinesplit:EReg = ~/^(.*?)(\n|\r\n|\r)/; // TODO: optimize without regexp

	//
	//public inline function setPage(page:$pageType, chars:String, x:Float=0, y:Float=0, size:Null<Float> = null, offset:Null<Float> = null, glyphStyle:Null<$styleType> = null):Bool
	//	if (size != null) line.size = size;
	//	if (offset != null) line.offset = offset;
		
	//	page.x = x;
	//	page.y = y;
	//	if (size != null) page.size = size;
	//	if (offset != null) page.offset = offset;
	//  var success = true;
	//	for (pageLine in page.pageLines) {
	//		if (!_setLine(pageLine, chars, x, y, size, offset, glyphStyle);
	//			success = false;
	//			break;
	//		}
	//  }
	//  return success;
	//}
	// TODO: change linecreation to have tabs (alternatively into creation of a tab-char into font!)
	// TODO: wrap and wordwrap
	public inline function setPage(page:Page<$styleType>, chars:String, x:Float=0, y:Float=0, size:Null<Float> = null, offset:Null<Float> = null, glyphStyle:$styleType = null):Bool
	{
		trace("setPage", chars);
		
/*		if (size != null) page.size = size;
		if (offset != null) page.offset = offset;		
		
		chars += "\n";
		
		var i:Int = 0;
		
		while (regLinesplit.match(chars) && i < page.length) { // overwrite old lines
			trace("setLine", i, regLinesplit.matched(1));
			var pageLine = page.getLine(i); // TODO: empty lines have no height !
			setPageLine( pageLine, regLinesplit.matched(1), x, y, glyphStyle); // TODO: autoupdate
			
			page.updateFrom = 0;
// TODO
			page.updateTo = regLinesplit.matched(1).length; // <- let setPageLine return how much was set up
			
			//updateLine(line);
			
			chars = regLinesplit.matchedRight();
			y += page.lineHeight;
			i++;
		}
		if (i < page.length) { // delete rest of old line
			var new_length:Int = i;
			while (i < page.length) {
				trace("removeLine", i);
				removeLine(page.getLine(i));
				i++;
			}
			page.resize(new_length); // TODO: caching
		}
		else { // create new lines and push them to page
			while (regLinesplit.match(chars)) {
				trace("pushLine", regLinesplit.matched(1));
				var line = createLine(regLinesplit.matched(1), x, y, glyphStyle); // TODO: empty lines have no height !
				page.pushLine( line );
				chars = regLinesplit.matchedRight();
				y += line.lineHeight;
			}
		}
*/		
		trace("new length:", page.length);
		
		return true;
	}
	
	
	
	
}

// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------
			
			Context.defineModule(classPackage.concat([className]).join('.'),[c]);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
}
#end
