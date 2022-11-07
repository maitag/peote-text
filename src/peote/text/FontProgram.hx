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
	
	public var skinPrograms:peote.text.skin.SkinProgramArray = null;
	
	var _buffer:peote.view.Buffer<$glyphType>;
	
	public inline function new(font:peote.text.Font<$styleType>, fontStyle:$styleType, isMasked:Bool = false, bufferMinSize:Int = 1024, bufferGrowSize:Int = 1024, bufferAutoShrink:Bool = true)
	{
		_buffer = new peote.view.Buffer<$glyphType>(bufferMinSize, bufferGrowSize, bufferAutoShrink);
		super(_buffer);
		
		if (isMasked) enableMasking();

		setFont(font);
		setFontStyle(fontStyle);
	}
	
	override public function addToDisplay(display:peote.view.Display, ?atProgram:peote.view.Program, addBefore:Bool=false)
	{
		super.addToDisplay(display, atProgram, addBefore);
		if (isMasked) maskProgram.addToDisplay(display, this, true);
		if (skinPrograms != null) {
			for (skinProgram in skinPrograms) {
				if (skinProgram.depthIndex < 0) skinProgram.addToDisplay(display, this, true);
				else skinProgram.addToDisplay(display);
			}
		}
	}
	
	override public function removeFromDisplay(display:peote.view.Display):Void
	{
		super.removeFromDisplay(display);
		if (isMasked) maskProgram.removeFromDisplay(display);
		if (skinPrograms != null) for (skinProgram in skinPrograms) skinProgram.removeFromDisplay(display);
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
		if (skinPrograms != null) for (skinProgram in skinPrograms) if (skinProgram.useMaskIfAvail) skinProgram.mask = peote.view.Mask.USE;
	}
	
	public inline function createMask(x:Int, y:Int, w:Int, h:Int, autoAdd = true):peote.text.MaskElement {
		var maskElement = new peote.text.MaskElement(x, y, w, h);
		if (autoAdd) maskBuffer.addElement(maskElement);
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

	public inline function setMask(maskElement:peote.text.MaskElement, x:Int, y:Int, w:Int, h:Int, autoUpdate = true):Void {
		maskElement.update(x, y, w, h);
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
	// --------------- Skin --------------------
	// -----------------------------------------
	// programs for background, selection, cursor etc.
	
	@:access(peote.text.skin)
	public inline function addSkin<T:peote.text.skin.SkinProgram>(skinProgram:T, ?depthIndex:Null<Int>, ?useMaskIfAvail:Null<Bool>):T {
	//public inline function addSkin(skinProgram:peote.text.skin.SkinProgram, ?depthIndex:Null<Int>, ?useMaskIfAvail:Null<Bool>):peote.text.skin.SkinProgram {
		if (useMaskIfAvail != null) skinProgram.useMaskIfAvail = useMaskIfAvail;
		if (isMasked && skinProgram.useMaskIfAvail) skinProgram.mask = peote.view.Mask.USE else skinProgram.mask = peote.view.Mask.OFF;
		
		if (skinPrograms == null) skinPrograms = new peote.text.skin.SkinProgramArray();
		skinPrograms.insertZSorted(skinProgram, this, depthIndex, useMaskIfAvail);
		
		return(skinProgram);
	}
		
	public inline function removeSkin(skinProgram:peote.text.skin.SkinProgram) {
		for (display in displays) skinProgram.removeFromDisplay(display);
		skinPrograms.remove(skinProgram);
	}
	
	public inline function skinElemToLine(skinProgram:peote.text.skin.SkinProgram, skinElement:peote.text.skin.SkinElement, line:$lineType, from:Null<Int> = null, to:Null<Int> = null, autoUpdate = true):peote.text.skin.SkinElement {
		if (from != null && to != null && from > to) {
			var tmp = to;
			to = from;
			from = tmp;
		}
		if (from == null || from < line.visibleFrom) from = (line.visibleFrom>0) ? line.visibleFrom-1 : line.visibleFrom;
		if (to == null || to > line.visibleTo - 1) to = (line.visibleTo < line.length) ? line.visibleTo : line.visibleTo - 1;	
		if (from > to) skinElement.w = 0;
		else {
			skinElement.x = Std.int(lineGetPositionAtChar(line, from));
			skinElement.y = Std.int(line.y);
			skinElement.w = Std.int(lineGetPositionAtChar(line, to+1)) - skinElement.x;	
			skinElement.h = Std.int(line.height);
			${switch (glyphStyleHasField.zIndex) {
				case true: switch (glyphStyleHasField.local_zIndex) {
					case true: macro skinElement.z = line.getGlyph(from).zIndex;
					default: macro skinElement.z = fontStyle.zIndex;
				}
				default: macro {}
			}}
		}
		if (autoUpdate) skinProgram.updateElement(skinElement);
		return(skinElement);
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
		setXPosition(glyph, charData, x);
		setYPosition(glyph, charData, y);
	}
	
	inline function setXPosition(glyph:$glyphType, charData:$charDataType, x:Float)
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
			}
			default: macro // ------- simple font -------
			{
				glyph.x = x;
			}
		}}
	}
	
	inline function setYPosition(glyph:$glyphType, charData:$charDataType, y:Float)
	{					
		${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_height) {
					case true: macro glyph.y = y + (charData.fontData.base - charData.metric.top) * glyph.height;									
					default: switch (glyphStyleHasField.height) {
						case true: macro glyph.y = y + (charData.fontData.base - charData.metric.top) * fontStyle.height;
						default: macro glyph.y = y + (charData.fontData.base - charData.metric.top) * font.config.height;
				}}}							
			}
			default: macro // ------- simple font -------
			{
				glyph.y = y;
			}
		}}
	}
	
	inline function getXPosition(glyph:$glyphType, charData:$charDataType):Float
	{					
		return ${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_width) {
					case true: macro glyph.x - charData.metric.left * glyph.width;
					default: switch (glyphStyleHasField.width) {
						case true: macro glyph.x - charData.metric.left * fontStyle.width;
						default: macro glyph.x - charData.metric.left * font.config.width;
				}}}
			}
			default: macro // ------- simple font -------
			{
				glyph.x;
			}
		}}
	}
	
	inline function getYPosition(glyph:$glyphType, charData:$charDataType):Float
	{					
		return ${switch (glyphStyleHasMeta.packed)
		{
			case true: macro // ------- Gl3Font -------
			{
				${switch (glyphStyleHasField.local_height) {
					case true: macro glyph.y - (charData.fontData.base - charData.metric.top) * glyph.height;									
					default: switch (glyphStyleHasField.height) {
						case true: macro glyph.y - (charData.fontData.base - charData.metric.top) * fontStyle.height;
						default: macro glyph.y - (charData.fontData.base - charData.metric.top) * font.config.height;
				}}}							
			}
			default: macro // ------- simple font -------
			{
				glyph.y;
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
	
	public inline function setStyle(glyph:$glyphType, glyphStyle:$styleType) {
		glyph.setStyle((glyphStyle != null) ? glyphStyle : fontStyle);
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
					
	public inline function createGlyph(charcode:Int, x:Float, y:Float, ?glyphStyle:$styleType, useMetric = false):$glyphType return _createGlyph(charcode, x, y, glyphStyle, useMetric, false);
	public inline function createGlyphAtBase(charcode:Int, x:Float, y:Float, ?glyphStyle:$styleType):$glyphType return _createGlyph(charcode, x, y, glyphStyle, true, true);
	inline function _createGlyph(charcode:Int, x:Float, y:Float, glyphStyle:$styleType, useMetric:Bool, atBaseline:Bool):$glyphType {
		var charData = getCharData(charcode);
		if (charData != null) {
			var glyph = new peote.text.Glyph<$styleType>();
			setStyle(glyph, glyphStyle);
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			if (useMetric) {
				if (atBaseline) setPosition(glyph, charData, x, y - _getBaseline(glyph, charData));
				else setPosition(glyph, charData, x, y);
			}	
			else {
				glyph.x = x;
				glyph.y = y;
			}
			_buffer.addElement(glyph);
			return glyph;
		} else return null;
	}
	
	public inline function glyphAdd(glyph:$glyphType):Void _buffer.addElement(glyph);
					
	public inline function glyphRemove(glyph:$glyphType):Void _buffer.removeElement(glyph);
		
	public inline function glyphSet(glyph:$glyphType, charcode:Int, x:Float, y:Float, ?glyphStyle:$styleType, useMetric = false):Bool return _setGlyph(glyph, charcode, x, y, glyphStyle, useMetric, false);
	public inline function glyphSetAtBase(glyph:$glyphType, charcode:Int, x:Float, y:Float, ?glyphStyle:$styleType):Bool return _setGlyph(glyph, charcode, x, y, glyphStyle, true, true);
	inline function _setGlyph(glyph:$glyphType, charcode:Int, x:Float, y:Float, glyphStyle:$styleType, useMetric:Bool, atBaseline:Bool):Bool {
		var charData = getCharData(charcode);
		if (charData != null) {
			setStyle(glyph, glyphStyle);
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			if (useMetric) {
				if (atBaseline) setPosition(glyph, charData, x, y - _getBaseline(glyph, charData));
				else setPosition(glyph, charData, x, y);
			}	
			else {
				glyph.x = x;
				glyph.y = y;
			}
			_buffer.addElement(glyph);
			return true;
		} else return false;
	}
					
	public inline function glyphSetStyle(glyph:$glyphType, glyphStyle:$styleType, useMetric = false) {
		if (useMetric) {
			var charData = getCharData(glyph.char);
			var old_base:Float = _getBaseline(glyph, charData);
			var old_x = getXPosition(glyph, charData);
			var old_y = getYPosition(glyph, charData);
			
			setStyle(glyph, glyphStyle);
			
			setPosition(glyph, charData, old_x, old_y + _baseLineOffset(old_base, glyph, charData));
		}
		else setStyle(glyph, glyphStyle);
	}

	public inline function glyphSetPosition(glyph:$glyphType, x:Float, y:Float, useMetric = false) _glyphSetPosition(glyph, x, y, useMetric, false);
	public inline function glyphSetPositionAtBase(glyph:$glyphType, x:Float, y:Float) _glyphSetPosition(glyph, x, y, true, true);
	inline function _glyphSetPosition(glyph:$glyphType, x:Float, y:Float, useMetric:Bool, atBaseline:Bool) {
		if (useMetric) {
			if (atBaseline) {
				var charData = getCharData(glyph.char);
				setPosition(glyph, charData, x, y - _getBaseline(glyph, charData));
			}
			else setPosition(glyph, getCharData(glyph.char), x, y);
		}
		else {
			glyph.x = x;
			glyph.y = y;
		}
	}

	public inline function glyphSetXPosition(glyph:$glyphType, x:Float, useMetric = false) {
		if (useMetric) setXPosition(glyph, getCharData(glyph.char), x) else glyph.x = x;
	}
	public inline function glyphGetXPosition(glyph:$glyphType, useMetric = false):Float {
		if (useMetric) return getXPosition(glyph, getCharData(glyph.char)) else return glyph.x;
	}

	public inline function glyphSetYPosition(glyph:$glyphType, y:Float, useMetric = false) _glyphSetYPosition(glyph, y, useMetric, false);
	public inline function glyphSetYPositionAtBase(glyph:$glyphType, y:Float) _glyphSetYPosition(glyph, y, true, true);
	inline function _glyphSetYPosition(glyph:$glyphType, y:Float, useMetric:Bool, atBaseline:Bool) {
		if (useMetric) {
			if (atBaseline) {
				var charData = getCharData(glyph.char);
				setYPosition(glyph, charData, y - _getBaseline(glyph, charData));
			}
			else setYPosition(glyph, getCharData(glyph.char), y);
		}
		else glyph.y = y;
	}

	public inline function glyphGetYPosition(glyph:$glyphType, useMetric = false):Float return _glyphGetYPosition(glyph, useMetric, false);
	public inline function glyphGetYPositionAtBase(glyph:$glyphType):Float return _glyphGetYPosition(glyph, true, true);
	inline function _glyphGetYPosition(glyph:$glyphType, useMetric:Bool, atBaseline:Bool):Float {
		if (useMetric) {
			if (atBaseline) {
				var charData = getCharData(glyph.char);
				return getYPosition(glyph, charData) + _getBaseline(glyph, charData);
			}
			else return getYPosition(glyph, getCharData(glyph.char));
		}
		else return glyph.y;
	}

	public inline function glyphGetBaseline(glyph:$glyphType):Float {
		return _getBaseline(glyph, getCharData(glyph.char));
	}

	public inline function glyphSetChar(glyph:$glyphType, charcode:Int, useMetric:Bool = false):Bool {
		var charData = getCharData(charcode);
		if (charData != null)
		{
			if (useMetric) {
				var old_charData = getCharData(glyph.char);
				var old_base:Float = _getBaseline(glyph, old_charData);
				var old_x = getXPosition(glyph, old_charData);
				var old_y = getYPosition(glyph, old_charData);
				
				setCharcode(glyph, charcode, charData);
				setSize(glyph, charData);
				
				setPosition(glyph, charData, old_x, old_y + _baseLineOffset(old_base, glyph, charData));
			}
			else {
				setCharcode(glyph, charcode, charData);
				setSize(glyph, charData);
			}
			return true;
		}
		else return false;
	}

	public inline function glyphUpdate(glyph:$glyphType):Void _buffer.updateElement(glyph);
	
	// ---------------------------------------------
	
	public inline function updateAllGlyphes():Void _buffer.update();
	
	public inline function numberOfGlyphes():Int return _buffer.length();

	
	// ---------------------------------------------
	// ---------------- PageLines ------------------
	// ---------------------------------------------
	public inline function createPageLine(chars:String, x:Float = 0.0, y:Float = 0.0, ?size:Null<Float>, ?offset:Null<Float>,
		?glyphStyle:Null<$styleType>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):$pageLineType
	{
		var pageLine = new peote.text.PageLine<$styleType>();
		pageLineSet(pageLine, chars, x, y, size, offset, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
		return pageLine;
	}
	
	public inline function pageLineAdd(pageLine:$pageLineType):Void
	{
		for (i in pageLine.visibleFrom...pageLine.visibleTo) glyphAdd(pageLine.getGlyph(i));
	}
	
	public inline function pageLineRemove(pageLine:$pageLineType)
	{
		for (i in pageLine.visibleFrom...pageLine.visibleTo) glyphRemove(pageLine.getGlyph(i));
	}

	public function pageLineSet(pageLine:$pageLineType, chars:String, x:Float, ?y:Null<Float>, size:Float, offset:Float,
		?glyphStyle:Null<$styleType>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void)
	{
		var line_max = x + size;
		if (y != null) pageLine.y = y;
		else y = pageLine.y;
		
		var x_start = x;
		x += offset;
		
		var glyph:$glyphType;
		var prev_glyph:$glyphType = null;
		var i = 0;
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
					setStyle(glyph, glyphStyle);
					setCharcode(glyph, charcode, charData);
					setSize(glyph, charData);
					
					x += kerningSpaceOffset(prev_glyph, glyph, charData);
					
					setPosition(glyph, charData, x, y);

					if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width;}} >= x_start) {														
						if (glyph.x < line_max) {
							if (addRemoveGlyphes) _buffer.addElement(glyph);
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
					if (glyphStyle != null) glyph.setStyle(glyphStyle);
					setCharcode(glyph, charcode, charData);
					setSize(glyph, charData);
					
					x += kerningSpaceOffset(prev_glyph, glyph, charData);
					
					setPosition(glyph, charData, x, y);
			
					if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width;}} >= x_start) {														
						if (glyph.x < line_max) {
							if (addRemoveGlyphes && (i < pageLine.visibleFrom || i >= pageLine.visibleTo)) _buffer.addElement(glyph);
							visibleTo ++;
						} else if (addRemoveGlyphes && i < pageLine.visibleTo) _buffer.removeElement(glyph);
					}
					else {
						if (addRemoveGlyphes && i >= pageLine.visibleFrom) _buffer.removeElement(glyph);
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
						var y_offset = _baseLineOffset(pageLine.base, glyph, charData);
						glyph.y += y_offset;
						y += y_offset;
					}
				}
				
				prev_glyph = glyph;
				i++;
			}
			else if (onUnrecognizedChar != null) onUnrecognizedChar(charcode, i);
		});
								
		if (i < old_length) {
			pageLineDeleteChars(pageLine, x_start, size, offset, i, null, addRemoveGlyphes);
			for (j in Std.int(Math.max(i, pageLine.visibleFrom))...Std.int(Math.min(pageLine.length, pageLine.visibleTo))) {
				if (addRemoveGlyphes) _buffer.removeElement(pageLine.getGlyph(j));
			}
			pageLine.resize(i);							
		}
		
		// for an empty line set line metric to a default fontrange or to the first range into font
		if (i == 0) _setDefaultMetric(pageLine, (defaultFontRange == null) ? 0 : defaultFontRange, glyphStyle);
				
		pageLine.updateFrom = 0;
		pageLine.updateTo = i;
		
		pageLine.visibleFrom = visibleFrom;
		pageLine.visibleTo = visibleTo;
		
		pageLine.textSize = x - x_start - offset;
	}	
	
	inline function _setDefaultMetric(pageLine:$pageLineType, defaultFontRange:Int, glyphStyle:Null<$styleType>) {
		var charCode = font.config.ranges[defaultFontRange].range.min;
		var charData = getCharData(charCode);
		var glyph = new peote.text.Glyph<$styleType>();
		setStyle(glyph, glyphStyle);
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
	
	inline function _getBaseline(glyph:$glyphType, charData:$charDataType):Float {
		${switch (glyphStyleHasMeta.packed) {
			case true: macro {
				return charData.fontData.base * ${switch (glyphStyleHasField.local_height) {
					case true: macro glyph.height;
					default: switch (glyphStyleHasField.height) {
						case true: macro fontStyle.height;
						default: macro font.config.height;
				}}}
			}
			default: macro {
				return charData.base * ${switch (glyphStyleHasField.local_height) {
					case true: macro glyph.height;
					default: switch (glyphStyleHasField.height) {
						case true: macro fontStyle.height;
						default: macro font.config.height;
				}}}
			}
		}}
	}
	
	inline function _baseLineOffset(base:Float, glyph:$glyphType, charData:$charDataType):Float {
		if (glyph != null) {
			${switch (glyphStyleHasMeta.packed) {
				case true: macro {
					return base - charData.fontData.base * ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
				}
				default: macro {
					return base - charData.base * ${switch (glyphStyleHasField.local_height) {
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
	
	public function pageLineSetStyle(pageLine:$pageLineType, x:Float, size:Float, offset:Float, glyphStyle:$styleType, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):Float {
		if (to == null || to > pageLine.length) to = pageLine.length;
		
		// swapping
		if (to < from) { var tmp = to; to = from; from = tmp; }
		else if (from == to) to++;
		
		if (from < pageLine.updateFrom) pageLine.updateFrom = from;
		if (to > pageLine.updateTo) pageLine.updateTo = to;
		
		var prev_glyph:$glyphType = null;
		
		var line_x = x;
		x += offset;
		var y = pageLine.y;
		
		if (from > 0) {
			x = rightGlyphPos(pageLine.getGlyph(from - 1), getCharData(pageLine.getGlyph(from - 1).char));
			prev_glyph = pageLine.getGlyph(from - 1);
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(from), getCharData(pageLine.getGlyph(from - 1).char));
		}
		
		// first
		pageLine.getGlyph(from).setStyle(glyphStyle); // OPTIMIZE: pageLine.getGlyph()
		var charData = getCharData(pageLine.getGlyph(from).char);
		
		y += _baseLineOffset(pageLine.base, pageLine.getGlyph(from), charData);
		
		setPosition(pageLine.getGlyph(from), charData, x, y);
		x += nextGlyphOffset(pageLine.getGlyph(from), charData);
				
		prev_glyph = pageLine.getGlyph(from);
		
		for (i in from+1...to)
		{
			pageLine.getGlyph(i).setStyle(glyphStyle); // OPTIMIZE: pageLine.getGlyph()
			charData = getCharData(pageLine.getGlyph(i).char);
			
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(i), charData);
			
			setPosition(pageLine.getGlyph(i), charData, x, y);
			x += nextGlyphOffset(pageLine.getGlyph(i), charData);
			prev_glyph = pageLine.getGlyph(i);
		}
		
		if (to < pageLine.length) // rest
		{
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(to), charData);
			
			var _offset = x - leftGlyphPos(pageLine.getGlyph(to), getCharData(pageLine.getGlyph(to).char));
			if (_offset != 0.0) {
				pageLine.updateTo = pageLine.length;
				_setLinePositionOffset(pageLine, line_x, size, _offset, from, to, pageLine.length, addRemoveGlyphes);
			}
			else _setLinePositionOffset(pageLine, line_x, size, _offset, from, to, to, addRemoveGlyphes);
			return _offset;
		} 
		else {
			var _offset = x - line_x - offset - pageLine.textSize;
			_setLinePositionOffset(pageLine, line_x, size, _offset, from, to, to, addRemoveGlyphes);
			return _offset;
		}
	}
	
	
	// ----------- change Line Position, Size and Offset ----------------

	public function pageLineSetPosition(pageLine:$pageLineType, x:Float, size:Float, offset:Float, xNew:Float, yNew:Float, ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		if (offsetNew != null) _setLinePositionOffsetFull(pageLine, xNew, size, offsetNew - offset + xNew - x, yNew - pageLine.y, addRemoveGlyphes);
		else
			for (i in 0...pageLine.length) {
				pageLine.getGlyph(i).x += xNew - x;
				pageLine.getGlyph(i).y += yNew - pageLine.y;
			}
		pageLine.y = yNew;
	}
	
	public function pageLineSetXPosition(pageLine:$pageLineType, x:Float, size:Float, offset:Float, xNew:Float, ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		if (offsetNew != null) _setLinePositionOffsetFull(pageLine, xNew, size, offsetNew - offset + xNew - x, 0, addRemoveGlyphes);
		else for (i in 0...pageLine.updateTo) pageLine.getGlyph(i).x += xNew - x;
	}
	
	public function pageLineSetYPosition(pageLine:$pageLineType, x:Float, size:Float, offset:Float, yNew:Float, ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		if (offsetNew != null) _setLinePositionOffsetFull(pageLine, x, size, offsetNew - offset, yNew - pageLine.y, addRemoveGlyphes);
		else for (i in 0...pageLine.updateTo) pageLine.getGlyph(i).y += yNew - pageLine.y;
		pageLine.y = yNew;
	}	
	
	public function pageLineSetPositionSize(pageLine:$pageLineType, x:Float, size:Float, offset:Float, xNew:Float, yNew:Float, ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		if (offsetNew != null) _setLinePositionOffsetFull(pageLine, xNew, size, offsetNew - offset + xNew - x,  yNew - pageLine.y, addRemoveGlyphes);
		else _setLinePositionOffsetFull(pageLine, xNew, size, xNew - x, yNew - pageLine.y, addRemoveGlyphes);		
		pageLine.y = yNew;
	}

	public function pageLineSetSize(pageLine:$pageLineType, x:Float, size:Float, offset:Float, ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;		
		if (offsetNew != null) _setLinePositionOffsetFull(pageLine, x, size, offsetNew - offset, null, addRemoveGlyphes);
		else _setLinePositionOffsetFull(pageLine, x, size, null, null, addRemoveGlyphes);
	}

	public function pageLineSetOffset(pageLine:$pageLineType, x:Float, size:Float, offset:Float, offsetNew:Float, addRemoveGlyphes:Bool = true)
	{
		pageLine.updateFrom = 0;
		pageLine.updateTo = pageLine.length;
		_setLinePositionOffsetFull(pageLine, x, size, offsetNew - offset, null, addRemoveGlyphes);
	}

	inline function _setLinePositionOffsetFull(pageLine:$pageLineType, x:Float, size:Float, deltaX:Null<Float>, deltaY:Null<Float>, addRemoveGlyphes:Bool) 
	{
		var line_max = x + size;
		
		var visibleFrom = pageLine.visibleFrom;
		var visibleTo = pageLine.visibleTo;
			
		for (i in 0...pageLine.length)
		{
			if (deltaX != null) pageLine.getGlyph(i).x += deltaX;
			if (deltaY != null) pageLine.getGlyph(i).y += deltaY;

			// calc visible range
			if (pageLine.getGlyph(i).x + ${switch(glyphStyleHasMeta.packed) {case true: macro pageLine.getGlyph(i).w; default: macro pageLine.getGlyph(i).width; }} >= x)
			{	
				if (pageLine.getGlyph(i).x < line_max) { // OPTIMIZE: pageLine.getGlyph()
					if (i < pageLine.visibleFrom || i >= pageLine.visibleTo) {
						if (addRemoveGlyphes) _buffer.addElement(pageLine.getGlyph(i));
						if (visibleFrom > i) visibleFrom = i;
						if (visibleTo < i + 1) visibleTo = i + 1;
					}
				} 
				else {
					if (addRemoveGlyphes && i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
					if (visibleTo > i) visibleTo = i;
				}
			}
			else {
				if (addRemoveGlyphes && i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
				visibleFrom = i + 1;
			}			
		}
		
		pageLine.visibleFrom = visibleFrom;
		pageLine.visibleTo = visibleTo;		
	}

	inline function _setLinePositionOffset(pageLine:$pageLineType, x:Float, size:Float, deltaX:Float, from:Int, withDelta:Int, to:Int, addRemoveGlyphes:Bool)
	{
		var line_max = x + size;
		var visibleFrom = pageLine.visibleFrom;
		var visibleTo = pageLine.visibleTo;

		for (i in from...to) {
			
			if (i >= withDelta) pageLine.getGlyph(i).x += deltaX;
			
			// calc visible range
			if (pageLine.getGlyph(i).x + ${switch(glyphStyleHasMeta.packed) {case true: macro pageLine.getGlyph(i).w; default: macro pageLine.getGlyph(i).width; }} >= x)
			{	
				if (pageLine.getGlyph(i).x < line_max) { // OPTIMIZE: pageLine.getGlyph()
					if (i < pageLine.visibleFrom || i >= pageLine.visibleTo) {
						if (addRemoveGlyphes) _buffer.addElement(pageLine.getGlyph(i));
						if (visibleFrom > i) visibleFrom = i;
						if (visibleTo < i + 1) visibleTo = i + 1;
					}
				} 
				else {
					if (addRemoveGlyphes && i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
					if (visibleTo > i) visibleTo = i;
				}
			}
			else {
				if (addRemoveGlyphes && i >= pageLine.visibleFrom && i < pageLine.visibleTo) _buffer.removeElement(pageLine.getGlyph(i));
				visibleFrom = i + 1;
			}
		}
		
		pageLine.visibleFrom = visibleFrom;
		pageLine.visibleTo = visibleTo;
		
		pageLine.textSize += deltaX; 
	}
	
	
	// ------------ set chars  ---------------
	
	public function pageLineSetChar(pageLine:$pageLineType, x:Float, size:Float, offset:Float, charcode:Int, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{
		if (position >= pageLine.length) position = pageLine.length - 1;
		else if (position < 0) position = 0;
		
		var charData = getCharData(charcode);
		if (charData != null)
		{			
			if (position < pageLine.updateFrom) pageLine.updateFrom = position;
			if (position + 1 > pageLine.updateTo) pageLine.updateTo = position + 1;
			
			var prev_glyph:$glyphType = null;
			
			var line_x = x;
			x += offset;
			var y = pageLine.y;
			
			if (position > 0) {
				x = rightGlyphPos(pageLine.getGlyph(position - 1), getCharData(pageLine.getGlyph(position - 1).char));  // OPTIMIZE: pageLine.getGlyph()
				prev_glyph = pageLine.getGlyph(position - 1);
			}
			
			if (glyphStyle != null) {
				pageLine.getGlyph(position).setStyle(glyphStyle);  // OPTIMIZE: pageLine.getGlyph()
				y += _baseLineOffset(pageLine.base, pageLine.getGlyph(position), charData);
			}
			setCharcode(pageLine.getGlyph(position), charcode, charData);
			setSize(pageLine.getGlyph(position), charData);
			
			x += kerningSpaceOffset(prev_glyph, pageLine.getGlyph(position), charData);
			
			setPosition(pageLine.getGlyph(position), charData, x, y);
			
			x += nextGlyphOffset(pageLine.getGlyph(position), charData);
			
			if (position+1 < pageLine.length) // rest
			{	
				x += kerningSpaceOffset(pageLine.getGlyph(position), pageLine.getGlyph(position+1), charData);  // OPTIMIZE: pageLine.getGlyph()
				
				var _offset = x - leftGlyphPos(pageLine.getGlyph(position+1), getCharData(pageLine.getGlyph(position+1).char));
				if (_offset != 0.0) {
					pageLine.updateTo = pageLine.length;
					_setLinePositionOffset(pageLine, line_x, size, _offset, position, position + 1, pageLine.length, addRemoveGlyphes);
				}
				else _setLinePositionOffset(pageLine, line_x, size, _offset, position, position + 1, position + 1, addRemoveGlyphes);
				return _offset;
			}
			else {
				var _offset = x - line_x - offset - pageLine.textSize;
				_setLinePositionOffset(pageLine, line_x, size, _offset, position, position + 1, position + 1, addRemoveGlyphes);
				return _offset;
			}
		} 
		else {
			if (onUnrecognizedChar != null) onUnrecognizedChar(charcode, position);
			return 0;					
		}
	}
	
	public function pageLineSetChars(pageLine:$pageLineType, x:Float, size:Float, offset:Float, chars:String, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{
		var restChars:String = null;
		
		if (position >= pageLine.length) {
			position = pageLine.length;
			return pageLineAppendChars(pageLine, x, size, offset, chars, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
		}
		else if (position < 0) position = 0;
		
		if (position + chars.length > pageLine.length) {
			restChars = chars.substr(chars.length -(position + chars.length - pageLine.length));
			chars = chars.substring(0, chars.length -(position + chars.length - pageLine.length));
		}
		
		var prev_glyph:$glyphType = null;
		
		var line_x = x;
		x += offset;
		var y = pageLine.y;
		
		if (position > 0) {
			x = rightGlyphPos(pageLine.getGlyph(position - 1), getCharData(pageLine.getGlyph(position - 1).char)); // OPTIMIZE: pageLine.getGlyph()
			prev_glyph = pageLine.getGlyph(position - 1);
		}

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
						pageLine.getGlyph(i).setStyle(glyphStyle); // OPTIMIZE: pageLine.getGlyph()
						if (i == position) // first
						{					
							y += _baseLineOffset(pageLine.base, pageLine.getGlyph(i), charData);
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
				else if (onUnrecognizedChar != null) onUnrecognizedChar(charcode, i);
			}
			else {
				// TODO: better using append here ?
				var _offset = pageLineInsertChar(pageLine, line_x, size, offset, charcode, i, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
				if (_offset > 0) {
					x += _offset;
					i++;
				}
			}
		});
		
		if (position < pageLine.updateFrom) pageLine.updateFrom = position;
		if (position + i > pageLine.updateTo) pageLine.updateTo = Std.int(Math.min(position + i, pageLine.length));
		
		if (i < pageLine.length) // rest
		{
			x += kerningSpaceOffset(pageLine.getGlyph(i-1), pageLine.getGlyph(i), charData);
			
			var _offset = x - leftGlyphPos(pageLine.getGlyph(i), getCharData(pageLine.getGlyph(i).char));
			if (_offset != 0.0) {
				pageLine.updateTo = pageLine.length;
				_setLinePositionOffset(pageLine, line_x, size, _offset, position, i, pageLine.length, addRemoveGlyphes);
			}
			else _setLinePositionOffset(pageLine, line_x, size, _offset, position, i, i, addRemoveGlyphes);
			if (restChars != null) return _offset + pageLineAppendChars(pageLine, line_x, size, offset, restChars, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
			else return _offset;
		}
		else {
			var _offset = x - line_x - offset - pageLine.textSize;
			_setLinePositionOffset(pageLine, line_x, size, _offset, position, i, i, addRemoveGlyphes);
			if (restChars != null) return _offset + pageLineAppendChars(pageLine, line_x, size, offset, restChars, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
			else return _offset;
		}
	}
	
		
	// ------------- inserting chars ---------------------
	
	public function pageLineInsertChar(pageLine:$pageLineType, x:Float, size:Float, offset:Float, charcode:Int, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{
		var charData = getCharData(charcode);
		if (charData != null)
		{
			var prev_glyph:$glyphType = null;
			
			var line_x = x;
			x += offset;
			var y = pageLine.y;
			
			if (position > 0) {
				if (position >= pageLine.length) position = pageLine.length;
				x = rightGlyphPos(pageLine.getGlyph(position - 1), getCharData(pageLine.getGlyph(position - 1).char));
				prev_glyph = pageLine.getGlyph(position - 1);
			} 
			else if (position < 0) position = 0;
			
			var x_start = x;
			
			var glyph = new peote.text.Glyph<$styleType>();
			
			setStyle(glyph, glyphStyle);
			
			y += _baseLineOffset(pageLine.base, glyph, charData);
			
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			
			x += kerningSpaceOffset(prev_glyph, glyph, charData);
			
			setPosition(glyph, charData, x, y);						
			
			x += nextGlyphOffset(glyph, charData);
			
			if (position < pageLine.length) {				
				if (position < pageLine.updateFrom) pageLine.updateFrom = position+1;
				pageLine.updateTo = pageLine.length + 1;
				if (position == 0) x += kerningSpaceOffset(glyph, pageLine.getGlyph(position+1), charData);				
				_setLinePositionOffset(pageLine, line_x, size, x - x_start, position, position, pageLine.length, addRemoveGlyphes);
			}
			else pageLine.textSize += x - x_start;
			
			pageLine.insertGlyph(position, glyph);
			
			if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width; }} >= line_x)
			{
				if (glyph.x < line_x + size) {
					if (addRemoveGlyphes) _buffer.addElement(glyph);
					pageLine.visibleTo++;
				}
			} 
			else {
				pageLine.visibleFrom++;
				pageLine.visibleTo++;
			}			
			return x - x_start;
		}
		else {
			if (onUnrecognizedChar != null) {
				if (position >= pageLine.length) position = pageLine.length;
				else if (position < 0) position = 0;
				onUnrecognizedChar(charcode, position);
			}
			return 0;
		}
	}
		
	public function pageLineInsertChars(pageLine:$pageLineType, x:Float, size:Float, offset:Float, chars:String, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
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

			var deltaX = _lineAppend(pageLine, line_x, size, offset, chars, x, y, prev_glyph, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);

			if (position == 0) {
				var kerningSpace = kerningSpaceOffset(pageLine.getGlyph(pageLine.length-1), rest[0], getCharData(rest[0].char));
				deltaX += kerningSpace;
				pageLine.textSize += kerningSpace;
			}
			
			if (deltaX != 0.0)
			{
				if (pageLine.length < pageLine.updateFrom) pageLine.updateFrom = pageLine.length;
				
				var line_max = line_x + size;				
				for (i in 0...rest.length) {
					rest[i].x += deltaX;
					
					if (rest[i].x + ${switch(glyphStyleHasMeta.packed) {case true: macro rest[i].w; default: macro rest[i].width; }} >= line_x)
					{	
						if (rest[i].x < line_max) {
							if (addRemoveGlyphes && (i < oldFrom || i >= oldTo)) {
								_buffer.addElement(rest[i]);
							}
							pageLine.visibleTo++;
						} else if (addRemoveGlyphes && i >= oldFrom && i < oldTo) {
							_buffer.removeElement(rest[i]);
						}
					}
					else {
						if (addRemoveGlyphes && i >= oldFrom && i < oldTo) {
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
		else return _lineAppend(pageLine, line_x, size, offset, chars, x, y, prev_glyph, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
	}
		

	// ------------- appending chars ---------------------
	
	public function pageLineAppendChars(pageLine:$pageLineType, x:Float, size:Float, offset:Float, chars:String,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{
		if (pageLine.length > 0) {
			var prev_glyph = pageLine.getGlyph(pageLine.length - 1);
			var fromX = rightGlyphPos(prev_glyph, getCharData(prev_glyph.char));
			return _lineAppend(pageLine, x, size, 0, chars, fromX, pageLine.y, prev_glyph, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
		}
		else return _lineAppend(pageLine, x, size, offset, chars, x, pageLine.y, null, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
	}
	
	inline function _lineAppend(pageLine:$pageLineType, line_x:Float, size:Float, offset:Float, chars:String, x:Float, y:Float, prev_glyph:peote.text.Glyph<$styleType>,
		glyphStyle:$styleType, addRemoveGlyphes:Bool, ?onUnrecognizedChar:Int->Int->Void):Float
	{
		var first = true;
		var glyph:$glyphType = null;
		var charData:$charDataType = null;
		
		x += offset;
		var x_start = x;
				
		var line_max = line_x + size;
		
		var i = pageLine.length - 1; // only for onUnrecognizedChar
		
		peote.text.util.StringUtils.iter(chars, function(charcode)
		{
			charData = getCharData(charcode);
			if (charData != null)
			{
				glyph = new peote.text.Glyph<$styleType>();
				pageLine.pushGlyph(glyph);
				setStyle(glyph, glyphStyle);

				if (first) {
					first = false;
					y += _baseLineOffset(pageLine.base, glyph, charData);
				}
				setCharcode(glyph, charcode, charData);
				setSize(glyph, charData);
				
				x += kerningSpaceOffset(prev_glyph, glyph, charData);
				
				setPosition(glyph, charData, x, y);
				
				if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width;}} >= line_x)  {
					if (glyph.x < line_max)	{
						if (addRemoveGlyphes) _buffer.addElement(glyph);
						pageLine.visibleTo ++;
					}
				}
				else {
					pageLine.visibleFrom ++;
					pageLine.visibleTo ++;
				}

				x += nextGlyphOffset(glyph, charData);

				prev_glyph = glyph;
				
				i++; // only for onUnrecognizedChar
			} 
			else if (onUnrecognizedChar != null) onUnrecognizedChar(charcode, i);
		});

		pageLine.textSize += x - x_start;
		
		return x - x_start;
	}
	
	
	// ------------- deleting chars ---------------------	

	public function pageLineDeleteChar(pageLine:$pageLineType, x:Float, size:Float, offset:Float, position:Int = 0, addRemoveGlyphes:Bool = true):Float
	{	
		if (addRemoveGlyphes && position >= pageLine.visibleFrom && position < pageLine.visibleTo) {
			_buffer.removeElement(pageLine.getGlyph(position));
		}
		
		var _offset = _pageLineDeleteCharsOffset(pageLine, x, size, offset, position, position + 1, addRemoveGlyphes);
		
		if (position < pageLine.visibleFrom) {
			pageLine.visibleFrom--; pageLine.visibleTo--;
		} 
		else if (position < pageLine.visibleTo) {
			pageLine.visibleTo--;
		}

		pageLine.splice(position, 1);
		
		return _offset;
	}
	
	public function pageLineDeleteChars(pageLine:$pageLineType, x:Float, size:Float, offset:Float, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):Float
	{
		if (to == null) to = pageLine.length;
		for (i in ((from < pageLine.visibleFrom) ? pageLine.visibleFrom : from)...((to < pageLine.visibleTo) ? to : pageLine.visibleTo)) {
			if (addRemoveGlyphes) _buffer.removeElement(pageLine.getGlyph(i));
		}
		return _pageLineDeleteChars(pageLine, x, size, offset, from, to, addRemoveGlyphes);
	}
	
	public function pageLineCutChars(pageLine:$pageLineType, x:Float, size:Float, offset:Float, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):String
	{
		if (to == null) to = pageLine.length;
		var cut = "";
		//for (i in ((from < pageLine.visibleFrom) ? pageLine.visibleFrom : from)...((to < pageLine.visibleTo) ? to : pageLine.visibleTo)) {
		for (i in from...to) {
			cut += String.fromCharCode(pageLine.getGlyph(i).char);
			if (i >= pageLine.visibleFrom && i < pageLine.visibleTo && addRemoveGlyphes) _buffer.removeElement(pageLine.getGlyph(i));
		}
		_pageLineDeleteChars(pageLine, x, size, offset, from, to, addRemoveGlyphes);
		return cut;
	}
	
	public function pageLineGetChars(pageLine:$pageLineType, from:Int = 0, ?to:Null<Int>):String
	{
		if (to == null) to = pageLine.length;
		var chars:String = "";
		for (glyph in pageLine.glyphes) {
			chars += String.fromCharCode(glyph.char);
		}
		return chars;
	}
	
	inline function _pageLineDeleteChars(pageLine:$pageLineType, x:Float, size:Float, offset:Float, from:Int, to:Int, addRemoveGlyphes:Bool):Float
	{
		var _offset = _pageLineDeleteCharsOffset(pageLine, x, size, offset, from, to, addRemoveGlyphes);
		
		if (from < pageLine.visibleFrom) {
			pageLine.visibleFrom = (to < pageLine.visibleFrom) ? pageLine.visibleFrom - to + from : from;
			pageLine.visibleTo = (to < pageLine.visibleTo) ? pageLine.visibleTo - to + from : from;
		}
		else if (from < pageLine.visibleTo) {
			pageLine.visibleTo = (to < pageLine.visibleTo) ? pageLine.visibleTo - to + from : from;
		}
		
		pageLine.splice(from, to - from);
		
		return _offset;
	}
	
	inline function _pageLineDeleteCharsOffset(pageLine:$pageLineType, x:Float, size:Float, offset:Float, from:Int, to:Int, addRemoveGlyphes:Bool):Float
	{
		var _offset:Float = 0.0; 
		if (to < pageLine.length) 
		{
			var charData = getCharData(pageLine.getGlyph(to).char);
			if (from == 0) {
				_offset = x + offset - leftGlyphPos(pageLine.getGlyph(to), charData);
			}
			else {
				_offset = rightGlyphPos(pageLine.getGlyph(from - 1), getCharData(pageLine.getGlyph(from - 1).char)) - leftGlyphPos(pageLine.getGlyph(to), charData);
				_offset += kerningSpaceOffset(pageLine.getGlyph(from-1), pageLine.getGlyph(to), charData);
			}
			
			if (pageLine.updateFrom > from) pageLine.updateFrom = from;
			pageLine.updateTo = pageLine.length - to + from;
			
			_setLinePositionOffset(pageLine, x, size, _offset, to, to, pageLine.length, addRemoveGlyphes);
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
				_offset = rightGlyphPos(pageLine.getGlyph(from - 1), getCharData(pageLine.getGlyph(from - 1).char)) - (x + offset + pageLine.textSize);
			else _offset = -pageLine.textSize;

			pageLine.textSize += _offset;
		}
		return _offset;
	}
	
	
	public function pageLineUpdate(pageLine:$pageLineType, ?from:Null<Int>, ?to:Null<Int>)
	{
		if (from != null) pageLine.updateFrom = from;
		if (to != null) pageLine.updateTo = to;
		
		//trace("visibleFrom: " + pageLine.visibleFrom+ "-" +pageLine.visibleTo);
		//trace("updateFrom : " +  pageLine.updateFrom + "-" +pageLine.updateTo);
		
		if (pageLine.updateTo > 0 )
		{
			if (pageLine.visibleFrom > pageLine.updateFrom) pageLine.updateFrom = pageLine.visibleFrom;
			if (pageLine.visibleTo < pageLine.updateTo) pageLine.updateTo = pageLine.visibleTo;
			//trace("--update from " + pageLine.updateFrom + " to " +pageLine.updateTo);
			
			for (i in pageLine.updateFrom...pageLine.updateTo) glyphUpdate(pageLine.getGlyph(i));

			pageLine.updateFrom = 0x1000000;
			pageLine.updateTo = 0;
		} //else trace("nothing to update");
	}
	
	public function pageLineGetPositionAtChar(pageLine:$pageLineType, x:Float, offset:Float, position:Int):Float
	{
		if (position == 0) return x + offset;
		else if (position < pageLine.length) {
			var right_glyph = pageLine.getGlyph(position);
			var chardata = getCharData(right_glyph.char);
			return (rightGlyphPos(pageLine.getGlyph(position - 1), chardata) + leftGlyphPos(right_glyph, chardata)) / 2;
		} else {
			var last_glyph = pageLine.getGlyph(pageLine.length-1);
			return rightGlyphPos(last_glyph, getCharData(last_glyph.char));
		}
	}
	
	public function pageLineGetCharAtPosition(pageLine:$pageLineType, x:Float, size:Float, offset:Float, xPosition:Float):Int
	{
		//if (xPosition <= x) return 0;
		if (xPosition <= x) return pageLine.visibleFrom;
		else if (xPosition >= x + size) return pageLine.visibleTo;
		else 
		{
			${switch (glyphStyleHasMeta.packed || glyphStyleHasField.local_width || glyphStyleHasField.local_letterSpace)
			{
				case true: macro
				{
					// TODO: binary search to optimze
					var i:Int = pageLine.visibleFrom;
					while (i < pageLine.visibleTo && xPosition > pageLine.getGlyph(i).x) i++;
					if (i == 0) return 0;
					var left_glyph = pageLine.getGlyph(i - 1);
					var chardata = getCharData(left_glyph.char);
					if ( xPosition < (leftGlyphPos(left_glyph, chardata) + rightGlyphPos(left_glyph, chardata)) / 2) return i-1;
					else return i;
				}
				default: switch (glyphStyleHasField.width) {
					case true: macro return Math.round((xPosition - x - offset + letterSpace(null)/2)/(fontStyle.width + letterSpace(null)));
					default: macro return Math.round((xPosition - x - offset + letterSpace(null)/2)/(font.config.width + letterSpace(null)));
				}
			}}
		}
	}
	
	// -----------------------------------------
	// ---------------- Lines ------------------
	// -----------------------------------------	
	/**
		Creates a new Line and returns it. The new created Line is displayed automatically.
		@param chars String that contains the chars (newlines have no effect)
		@param x horizontal position of the upper left pixel of the line, is 0 by default
		@param y vertical position of the upper left pixel of the line, is 0 by default
		@param size (optional) limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param glyphStyle (optional) GlyphStyle of the line, by default it is using the default FontStyle of the FontProgram 
		@param defaultFontRange (optional) unicode range of the Font where to fetch the line-metric from (by default it's using the metric from the range of the first letter)
		@param onUnrecognizedChar (optional) the function that is called whenever the font does not contain a char
	**/
	public inline function createLine(chars:String, x:Float, y:Float, ?size:Null<Float>, ?offset:Null<Float>,
		?glyphStyle:Null<$styleType>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):$lineType
	{
		var line = new peote.text.Line<$styleType>();
		lineSet(line, chars, x, y, size, offset, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
		return line;
	}
	
	/**
		Add the line to FontProgram to display it.
		@param line the Line instance
	**/
	public inline function lineAdd(line:$lineType):Void pageLineAdd(line.pageLine);
	
	/**
		Removes the line from FontProgram to not display it anymore.
		@param line the Line instance
	**/
	public inline function lineRemove(line:$lineType):Void pageLineRemove(line.pageLine);
	
	/**
		Changing all chars of an existing Line. (can be faster than creating a new line)
		Returns false if the font don't contain one of the chars.
		@param line the Line instance
		@param chars String that contains the chars (newlines have no effect)
		@param x horizontal position of the upper left pixel of the line, is 0 by default
		@param y vertical position of the upper left pixel of the line, is 0 by default
		@param size (optional) limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param glyphStyle (optional) GlyphStyle of the line, by default it is using the default FontStyle of the FontProgram 
		@param defaultFontRange (optional) unicode range of the Font where to fetch the line-metric from (by default it's using the metric from the range of the first letter)
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
		@param onUnrecognizedChar (optional) the function that is called whenever the font does not contain a char
	**/
	public inline function lineSet(line:$lineType, chars:String, ?x:Null<Float>, ?y:Null<Float>, ?size:Null<Float>, ?offset:Null<Float>,
		?glyphStyle:Null<$styleType>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void)
	{
		if (x != null) line.x = x;
		if (size != null) line.size = size;
		if (offset != null) line.offset = offset;		
		pageLineSet(line.pageLine, chars, x, y, line.size, line.offset, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
	}
	
	/**
		Changing the style of glyphes in an existing Line. Needs lineUpdate() after to get effect.
		Returns the offset about how the textSize was changed.
		@param line Line instance
		@param glyphStyle new GlyphStyle
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineSetStyle(line:$lineType, glyphStyle:$styleType, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):Float
	{
		return pageLineSetStyle(line.pageLine, line.x, line.size, line.offset, glyphStyle, from, to, addRemoveGlyphes);
	}
	
	/**
		Set the position of a Line. Needs lineUpdate() after to get effect.
		@param line Line instance
		@param x horizontal position of the upper left pixel of the line
		@param y vertical position of the upper left pixel of the line
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineSetPosition(line:$lineType, x:Float, y:Float, ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLineSetPosition(line.pageLine, line.x, line.size, line.offset, x, y, offset, addRemoveGlyphes);
		line.x = x;
		if (offset != null) line.offset = offset;
	}
	
	/**
		Set the x position of a Line. Needs lineUpdate() after to get effect.
		@param line Line instance
		@param x horizontal position of the upper left pixel of the line
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineSetXPosition(line:$lineType, x:Float, ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLineSetXPosition(line.pageLine, line.x, line.size, line.offset, x, offset, addRemoveGlyphes);
		line.x = x;
		if (offset != null) line.offset = offset;
	}
	
	/**
		Set the y position of a Line. Needs lineUpdate() after to get effect.
		@param line Line instance
		@param y vertical position of the upper left pixel of the line
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineSetYPosition(line:$lineType, y:Float, ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLineSetYPosition(line.pageLine, line.x, line.size, line.offset, y, offset, addRemoveGlyphes);
		if (offset != null) line.offset = offset;
	}
	
	/**
		Set the position and size of a Line. Needs lineUpdate() after to get effect.
		@param line Line instance
		@param x horizontal position of the upper left pixel of the line
		@param y vertical position of the upper left pixel of the line
		@param size limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineSetPositionSize(line:$lineType, x:Float, y:Float, size:Float, ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLineSetPositionSize(line.pageLine, line.x, size, line.offset, x, y, offset, addRemoveGlyphes);
		line.x = x;
		line.size = size;
		if (offset != null) line.offset = offset;
	}
		
	/**
		Set the size of a Line. Needs lineUpdate() after to get effect.
		@param line Line instance
		@param size limits the line-size in pixel, so only glyphes inside this range will be displayed
		@param offset (optional) how much pixels the line is shifted inside it's visible range
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineSetSize(line:$lineType, size:Float, ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
	{
		pageLineSetSize(line.pageLine, line.x, size, line.offset, offset, addRemoveGlyphes);
		line.size = size;
		if (offset != null) line.offset = offset;
	}
		
	/**
		Set the offset of how much the Line is shifted. Needs lineUpdate() after to get effect.
		@param line Line instance where to change the style
		@param offset how much pixels the line is shifted inside it's visible range
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineSetOffset(line:$lineType, offset:Float, addRemoveGlyphes:Bool = true)
	{
		pageLineSetOffset(line.pageLine, line.x, line.size, line.offset, offset, addRemoveGlyphes);
		line.offset = offset;
	}

	/**
		Changing a char inside of a Line. Needs lineUpdate() after to get effect. Returns the offset about how the textSize was changed.
		@param line the Line instance
		@param charcode the unicode number of the char (newline have no effect)
		@param position where to change the char, is 0 by default (first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
		@param onUnrecognizedChar (optional) the function that is called whenever the font does not contain a char
	**/
	public inline function lineSetChar(line:$lineType, charcode:Int, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{
		return pageLineSetChar(line.pageLine, line.x, line.size, line.offset, charcode, position, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
	}
	
	/**
		Changing the chars inside of a Line. Needs lineUpdate() after to get effect. Returns the offset about how the textSize was changed.
		@param line the Line instance
		@param chars String that contains the letters (newlines have no effect)
		@param position where to change, is 0 by default (first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
		@param onUnrecognizedChar (optional) the function that is called whenever the font does not contain a char
	**/
	public inline function lineSetChars(line:$lineType, chars:String, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{
		return pageLineSetChars(line.pageLine, line.x, line.size, line.offset, chars, position, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);		
	}
	
	/**
		Insert a new char into a Line. If it's not inserted at end of line it needs lineUpdate() after to get effect.
		Returns the offset about how the textSize was changed.
		@param line the Line instance
		@param charcode the unicode number of the new char (newline have no effect)
		@param position where to insert, is 0 by default (before first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
		@param onUnrecognizedChar (optional) the function that is called whenever the font does not contain a char
	**/
	public inline function lineInsertChar(line:$lineType, charcode:Int, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{		
		return pageLineInsertChar(line.pageLine, line.x, line.size, line.offset, charcode, position, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
	}
	
	/**
		Insert new chars into a Line. If it's not inserted at end of line it needs lineUpdate() after to get effect.
		Returns the offset about how the textSize was changed.
		@param line the Line instance
		@param chars String that contains the new letters (newlines have no effect)
		@param position where to insert, is 0 by default (before first char into line)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
		@param onUnrecognizedChar (optional) the function that is called whenever the font does not contain a char
	**/
	public inline function lineInsertChars(line:$lineType, chars:String, position:Int = 0,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
	{		
		return pageLineInsertChars(line.pageLine, line.x, line.size, line.offset, chars, position, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
	}
	
	/**
		Append new chars at end of a Line. Returns the offset about how the textSize was changed.
		@param line the Line instance
		@param chars String that contains the new chars (newlines have no effect)
		@param glyphStyle (optional) GlyphStyle of the new chars, by default it is using the default FontStyle of the FontProgram 
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
		@param onUnrecognizedChar (optional) the function that is called whenever the font does not contain a char
	**/
	public inline function lineAppendChars(line:$lineType, chars:String,
		?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float 
	{
		return pageLineAppendChars(line.pageLine, line.x, line.size, line.offset, chars, glyphStyle, addRemoveGlyphes, onUnrecognizedChar);
	}
	
	/**
		Delete a char from a Line and returns the offset of how much the line was shrinked.
		If it's not the last char into line it needs lineUpdate() after to get effect.
		@param line the Line instance
		@param position where to delete, is 0 by default (first char into line)
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineDeleteChar(line:$lineType, position:Int = 0, addRemoveGlyphes:Bool = true):Float
	{
		return pageLineDeleteChar(line.pageLine, line.x, line.size, line.offset, position, addRemoveGlyphes);
	}
	
	/**
		Delete chars from a Line and returns the offset of how much the line was shrinked.
		If it's not the last chars into line it needs lineUpdate() after to get effect.
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineDeleteChars(line:$lineType, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):Float
	{
		return pageLineDeleteChars(line.pageLine, line.x, line.size, line.offset, from, to, addRemoveGlyphes);
	}
	
	/**
		Delete chars from a Line and returns it as a String. If it's not the last chars it needs lineUpdate() after to get effect.
		@param line the Line instance
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
		@param addRemoveGlyphes (optional) set this to false if the line is not added to prevent also adding/removing of glyphes
	**/
	public inline function lineCutChars(line:$lineType, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):String
	{
		return pageLineCutChars(line.pageLine, line.x, line.size, line.offset, from, to, addRemoveGlyphes);
	}
	
	/**
		Returns the chars from a Line as a String.
		@param line the Line instance
		@param from position of the first char into range, is 0 by default (start of line)
		@param to position after the last char into range, is line.length by default (end of line)
	**/
	public inline function lineGetChars(line:$lineType, from:Int = 0, ?to:Null<Int>):String
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
	public inline function lineUpdate(line:$lineType, ?from:Null<Int>, ?to:Null<Int>):Void pageLineUpdate(line.pageLine, from, to);
	
	/**
		Returns the x pixel-value of the middle position between a char and its previous char into a line.
		This function can be used to calculate a cursor-position.
		@param line the Line instance
		@param position index of the char into the line (0 returns the position before the first char)
	**/
	public inline function lineGetPositionAtChar(line:$lineType, position:Int):Float
	{
		return pageLineGetPositionAtChar(line.pageLine, line.x, line.offset, position);
	}
					
	/**
		Returns the index of the nearest visible char at a given x pixel-value.
		This function can be used to pick a char by mouse-position.
		@param line the Line instance
		@param xPosition x pixel-value at where to pick the nearest char
	**/
	public inline function lineGetCharAtPosition(line:$lineType, xPosition:Float):Int
	{
		return pageLineGetCharAtPosition(line.pageLine, line.x, line.size, line.offset, xPosition);
	}
		

	// T O D O
	
	// -----------------------------------------
	// ---------------- Pages ------------------
	// -----------------------------------------

	public inline function createPage(chars:String, x:Float, y:Float, ?width:Null<Float>, ?height:Null<Float>, ?xOffset:Null<Float>, ?yOffset:Null<Float>,
		glyphStyle:Null<$styleType> = null, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Int->Void):peote.text.Page<$styleType>
	{
		var page = new peote.text.Page<$styleType>();
		pageSet(page, chars, x, y, width, height, xOffset, yOffset, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
		return page;
	}
	
	public inline function pageAdd(page:Page<$styleType>)
	{
		for (i in page.visibleLineFrom...page.visibleLineTo) pageLineAdd(page.getPageLine(i));
	}
	
	public inline function pageRemove(page:Page<$styleType>)
	{
		for (i in page.visibleLineFrom...page.visibleLineTo) pageLineRemove(page.getPageLine(i));
	}
	

	static var regLinesplit:EReg = ~/^(.*?)(\n|\r\n|\r)/;

	// TODO: change linecreation to have tabs (alternatively into creation of a tab-char into font!)
	// TODO: wrap and wordwrap
	public function pageSet(page:Page<$styleType>, chars:String, ?x:Null<Float>, ?y:Null<Float>, ?width:Null<Float>, ?height:Null<Float>, ?xOffset:Null<Float>, ?yOffset:Null<Float>,
		?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Int->Void)
	{
		//trace("setPage --------", addRemoveGlyphes);
		
		if (x != null) page.x = x;
		if (y != null) page.y = y; else y = page.y;
		if (width != null) page.width = width;
		if (height != null) page.height = height;
		if (xOffset != null) page.xOffset = xOffset;	
		if (yOffset != null) page.yOffset = yOffset;
		
		chars += "\n";
		
		var visibleLineFrom:Int = 0;
		var visibleLineTo:Int = 0;
		var i:Int = 0;
				
		y += page.yOffset;
		
		while (i < page.length && regLinesplit.match(chars)) // overwrite old lines
		{
			//trace("setLine", i, regLinesplit.matched(1));			
			var pageLine = page.getPageLine(i);
			
			if (i > visibleLineFrom) {
				pageLineSet( pageLine, regLinesplit.matched(1), page.x, y, page.width, page.xOffset, glyphStyle, defaultFontRange, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo), onUnrecognizedChar.bind(i) );
				if (y <= page.y + page.height) {
					// add it if it was NOT visible before
					if (  addRemoveGlyphes && ( !(page.visibleLineFrom <= i && i < page.visibleLineTo) )  ) pageLineAdd(pageLine);
					visibleLineTo++;
				}
				else {	// remove it if it was visible before
					if (addRemoveGlyphes && page.visibleLineFrom <= i && i < page.visibleLineTo) pageLineRemove(pageLine);	
				}
			}
			else {
				// at first it is creating to fetch its line-height after
				pageLineSet( pageLine, regLinesplit.matched(1), page.x, y, page.width, page.xOffset, glyphStyle, defaultFontRange, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo), onUnrecognizedChar.bind(i) );
				if (y + pageLine.lineHeight < page.y) {
					// remove it if it was visible before
					if (addRemoveGlyphes && page.visibleLineFrom <= i && i < page.visibleLineTo) pageLineRemove(pageLine);	
					visibleLineFrom++;
					visibleLineTo++;
				}
				else { // add it if it was NOT visible before
					if (  addRemoveGlyphes && ( !(page.visibleLineFrom <= i && i < page.visibleLineTo) )  ) pageLineAdd(pageLine);
					visibleLineTo++;
				}
			}
						
			i++;			
			y += pageLine.lineHeight;			
			chars = regLinesplit.matchedRight();
		}
		
		// --------------------------------
		page.updateLineFrom = 0;		
		page.updateLineTo = i;
		
		if (i < page.length)
		{
			// ----------- remove rest of old lines ------------
			while (addRemoveGlyphes && page.visibleLineFrom <= i && i < page.visibleLineTo) // && i < page.length
			{
				trace("removeLine", i);
				pageLineRemove(page.getPageLine(i));
				i++;
			}
			page.resize(page.updateLineTo); // TODO: optimize
			
			page.visibleLineFrom = visibleLineFrom;
			page.visibleLineTo = visibleLineTo;
		}
		else // ----------- appending the rest ------
		{
			y += _pageAppendChars(page, chars, i, y, visibleLineFrom, visibleLineTo, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
		}
		
		page.textHeight = y - page.yOffset - page.y;
	}
	
	// ------------ appending helper ----------	
	inline function _pageAppendChars(page:Page<$styleType>, chars:String, i:Int, y:Float, visibleLineFrom:Int, visibleLineTo:Int, ?glyphStyle:$styleType, defaultFontRange:Null<Int>, addRemoveGlyphes:Bool, onUnrecognizedChar:Int->Int->Int->Void):Float
	{
		var y_start = y;
		while (regLinesplit.match(chars)) 
		{
			//trace("append PageLine", regLinesplit.matched(1));			
			var pageLine = new peote.text.PageLine<$styleType>();
			if (i > visibleLineFrom) {
				if (y <= page.y + page.height) {
					pageLineSet( pageLine, regLinesplit.matched(1), page.x, y, page.width, page.xOffset, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar.bind(i));
					visibleLineTo++;
				}
				else pageLineSet( pageLine, regLinesplit.matched(1), page.x, y, page.width, page.xOffset, glyphStyle, defaultFontRange, false, onUnrecognizedChar.bind(i));
			}
			else {
				// at first it is creating to fetch its line-height after
				pageLineSet( pageLine, regLinesplit.matched(1), page.x, y, page.width, page.xOffset, glyphStyle, defaultFontRange, false, onUnrecognizedChar.bind(i));
				if (y + pageLine.lineHeight < page.y) {
					visibleLineFrom++;
					visibleLineTo++;
				}
				else {
					if (addRemoveGlyphes) pageLineAdd(pageLine); // show it if line-height is inside
					visibleLineTo++;
				}
			}
			i++;
			y += pageLine.lineHeight;				
			page.pushLine( pageLine );
			chars = regLinesplit.matchedRight();
		}
		page.visibleLineFrom = visibleLineFrom;
		page.visibleLineTo = visibleLineTo;
		return y - y_start;
	}
	
	public function pageAppendChars(page:Page<$styleType>, chars:String, ?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Int->Void):Float
	{
		//if (page.length < page.updateLineFrom) page.updateLineFrom = page.length;

		chars += "\n";
		var offset:Float = 0;
		if (page.length > 0) {
			if ( regLinesplit.match(chars) ) {
				var i:Int = page.length-1;
				var pageLine = page.getPageLine(i);
				pageLineAppendChars( pageLine, page.x, page.width, page.xOffset, regLinesplit.matched(1), glyphStyle, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo), onUnrecognizedChar.bind(i));
				offset = _pageAppendChars(page, regLinesplit.matchedRight(), ++i, pageLine.y + pageLine.lineHeight, page.visibleLineFrom, page.visibleLineTo, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
			}
		}
		else offset = _pageAppendChars(page, chars, 0, page.y, 0, 0, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
		
		//if (page.length > page.updateLineTo) page.updateLineTo = page.length;

		page.textHeight += offset;		
		return offset;
	}
		
	//TODO:
	//public function pageSetStyle(page:Page<$styleType>, glyphStyle:$styleType, fromLine:Int = 0, ?toLine:Null<Int>, addRemoveGlyphes:Bool = true):Float {
		//return 0;
	//}

	public function pageInsertChars(page:Page<$styleType>, chars:String, lineNumber:Int = 0, position:Int = 0, ?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Int->Void):Float
	{
		chars += "\n";
		var offset:Float = 0.0;
		
		if (page.length > 0 && lineNumber < page.length)
		{
			if ( regLinesplit.match(chars) ) 
			{
				var pageLine = page.getPageLine(lineNumber);
				if (regLinesplit.matchedRight().length == 0) // no more chars, only a single line to insert
				{ 	//trace("single line to insert");
					// TODO: only if page was not empty before
					if (lineNumber < page.updateLineFrom) page.updateLineFrom = lineNumber;
					if (lineNumber >= page.updateLineTo) page.updateLineTo = lineNumber+1;

					pageLineInsertChars( pageLine, page.x, page.width, page.xOffset, regLinesplit.matched(1), position, glyphStyle, addRemoveGlyphes && (page.visibleLineFrom <= lineNumber && lineNumber < page.visibleLineTo), onUnrecognizedChar.bind(lineNumber));
				}
				else 
				{	// trace("multiple lines to insert");
					
					// cutting only glyph-array
					var restChars = pageLine.splice(position, pageLine.length - position);
					var oldFrom:Int = 0;
					var oldTo:Int = 0;
										
					if (restChars.length > 0) 
					{ 	//trace(pageLine.visibleFrom, pageLine.visibleTo,  pageLine.length);
						//if (lineNumber < page.updateLineFrom) page.updateLineFrom = lineNumber;
						//if (lineNumber >= page.updateLineTo) page.updateLineTo = lineNumber + 1;
						
						oldFrom = pageLine.visibleFrom - pageLine.length;
						oldTo = pageLine.visibleTo - pageLine.length;
						if (pageLine.visibleFrom > pageLine.length) pageLine.visibleFrom = pageLine.length;
						if (pageLine.visibleTo > pageLine.length) pageLine.visibleTo = pageLine.length;
					}
					
					var oldLineFrom = page.visibleLineFrom;
					var oldLineTo = page.visibleLineTo;
					
					pageLineAppendChars( pageLine, page.x, page.width, page.xOffset, regLinesplit.matched(1), glyphStyle, addRemoveGlyphes && (page.visibleLineFrom <= lineNumber && lineNumber < page.visibleLineTo), onUnrecognizedChar.bind(lineNumber));
					
					// cutting off all after lineNumber
					var restLines:Array<PageLine<$styleType>> = page.spliceLines(lineNumber+1, page.length - (lineNumber+1));
					var restLineFrom = page.length;
					var addRemoveRest:Bool = addRemoveGlyphes && (page.visibleLineFrom <= restLineFrom && restLineFrom < page.visibleLineTo);
					
					// and then appending all the new chars:
					offset = _pageAppendChars(page, regLinesplit.matchedRight(), page.length, pageLine.y + pageLine.lineHeight,
						(page.visibleLineFrom > page.length) ? page.length : page.visibleLineFrom, 
						(page.visibleLineTo > page.length) ? page.length : page.visibleLineTo, 
						glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
					
					// append the rest glyphes to last appended pageLine!
					if (restChars.length > 0) {
						
						var pageLine = page.getPageLine(page.length-1);
						if (pageLine.length < pageLine.updateFrom) pageLine.updateFrom = pageLine.length;
						
						var line_max =  page.x + page.width;
						
						// xOffset of the last char into last line from what was append
						//var deltaX = pageLine.textSize - restChars[0].x + page.x; //trace( leftGlyphPos( restChars[0], getCharData(restChars[0].char)), restChars[0].x  );
						var deltaX = pageLine.textSize - leftGlyphPos( restChars[0], getCharData(restChars[0].char)) + page.x;
						//var deltaX = 0 - leftGlyphPos( restChars[0], getCharData(restChars[0].char)) + page.x;
						
						if (pageLine.length > 0) {
							//var fromX = rightGlyphPos(pageLine.getGlyph(pageLine.length - 1), getCharData(pageLine.getGlyph(pageLine.length - 1).char)); // OPTIMIZE: pageLine.getGlyph()
							//trace(page.x + pageLine.textSize, fromX);
							//deltaX += fromX - page.x;
							deltaX += kerningSpaceOffset(pageLine.getGlyph(pageLine.length - 1), restChars[0], getCharData(restChars[0].char));
						}
						 // TODO
						//trace("Y",glyphGetYPositionAtBase(restChars[0]) ,  pageLine.y + pageLine.base );
						var deltaY = pageLine.y + pageLine.base - glyphGetYPositionAtBase(restChars[0]);
						var lineNotVisibleAnymore:Bool = (restChars[0].y + deltaY > page.y + page.height);
						
						for (i in 0...restChars.length)
						{
							restChars[i].x += deltaX;
							restChars[i].y += deltaY;
							
							// TODO: remove also from buffer if line is not visible anymore after offset
							if (lineNotVisibleAnymore) {
								if (addRemoveRest && i >= oldFrom && i < oldTo) _buffer.removeElement(restChars[i]);
							}
							else if (restChars[i].x + ${switch(glyphStyleHasMeta.packed) {case true: macro restChars[i].w; default: macro restChars[i].width; }} >= page.x)
							{	
								if (restChars[i].x < line_max) {
									if (addRemoveRest && (i < oldFrom || i >= oldTo)) {
										_buffer.addElement(restChars[i]);
									}
									pageLine.visibleTo++;
								} else if (addRemoveRest && i >= oldFrom && i < oldTo) {
									_buffer.removeElement(restChars[i]);
								}
							}
							else {
								if (addRemoveRest && i >= oldFrom && i < oldTo) {
									_buffer.removeElement(restChars[i]);
								}
								pageLine.visibleFrom++;
								pageLine.visibleTo++;
							}
						}
						
						pageLine.append(restChars);
						pageLine.updateTo = pageLine.length;
						//trace(pageLine.updateFrom, pageLine.updateTo);
						
						if (page.length-1 < page.updateLineFrom) page.updateLineFrom = page.length-1;
						if (page.length > page.updateLineTo) page.updateLineTo = page.length;
					}
						
					if (restLines.length > 0) 
					{
						//if (pageLine.length < pageLine.updateFrom) pageLine.updateFrom = pageLine.length;
						if (page.length < page.updateLineFrom) page.updateLineFrom = page.length;
						
						// concat the restLines to page again
						page.append(restLines);
						
						// after all set y-offset of the rest of lines:
						//_setPagePosSizeOffset(page, page.length - restLines.length, _SET_POS, null, page.y, null, offset, addRemoveGlyphes);
						var visibleLineFrom = page.visibleLineFrom;
						var visibleLineTo = page.visibleLineTo;
						var fromLine = page.length - restLines.length;
						
						trace("restLineFrom:",restLineFrom, "oldLineFrom:", oldLineFrom, "oldLineTo:", oldLineTo, pageLineGetChars(pageLine) );
						
						for (i in fromLine...page.length)
						{
							var pageLine = page.getPageLine(i);
							
							pageLineSetYPosition(pageLine, page.x, page.width, page.xOffset, offset + pageLine.y, null, 
								//addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
								addRemoveGlyphes && (oldLineFrom <= restLineFrom && restLineFrom < oldLineTo));
							
							// add or remove if inside visible area
							if (pageLine.y + pageLine.lineHeight >= page.y)
							{	
								if (pageLine.y < page.y + page.height) {
									if (i < page.visibleLineFrom || i >= page.visibleLineTo) {
										if (addRemoveGlyphes && !(restLineFrom >= oldLineFrom && restLineFrom < oldLineTo)) pageLineAdd(pageLine);
										if (visibleLineFrom > i) visibleLineFrom = i;
										if (visibleLineTo < i + 1) visibleLineTo = i + 1;
									}
								} 
								else {
									if (addRemoveGlyphes && restLineFrom >= oldLineFrom && restLineFrom < oldLineTo) pageLineRemove(pageLine);
									if (visibleLineTo > i) visibleLineTo = i;
								}
							}
							else {
								if (addRemoveGlyphes && restLineFrom >= oldLineFrom && restLineFrom < oldLineTo) pageLineRemove(pageLine);
								visibleLineFrom = i + 1;
							}
							restLineFrom++;
						}
						
						page.visibleLineFrom = visibleLineFrom;
						page.visibleLineTo = visibleLineTo;
						// -----------
						
						if (page.length > page.updateLineTo) page.updateLineTo = page.length;
					}
					
				}
			}
		}
		else {
			offset = _pageAppendChars(page, chars, page.length, page.y + page.textHeight, page.visibleLineFrom, page.visibleLineTo, glyphStyle, defaultFontRange, addRemoveGlyphes, onUnrecognizedChar);
			page.updateLineFrom = 0;
			page.updateLineTo = page.length;
		}
		
		page.textHeight += offset;
		return offset;
	}

	
	
	
	
	
	
	
	// ------------ position, size and offset -------------------
	public function pageSetPosition(page:Page<$styleType>, x:Float, y:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;		
		if (yOffset != null) _setPagePosSizeOffset(page, _SET_POS, x, y, xOffset, yOffset, addRemoveGlyphes);
		else
			for (i in 0...page.length) {
				var pageLine = page.getPageLine(i);
				pageLineSetPosition(pageLine, page.x, page.width, page.xOffset, x, pageLine.y + y - page.y, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
			}
		page.x = x;
		page.y = y;
		if (xOffset != null) page.xOffset = xOffset;
		if (yOffset != null) page.yOffset = yOffset;
	}
	
	public function pageSetXPosition(page:Page<$styleType>, x:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;		
		if (yOffset != null) _setPagePosSizeOffset(page, _SET_POS, x, page.y, xOffset, yOffset, addRemoveGlyphes);
		else
			for (i in 0...page.length) {
				var pageLine = page.getPageLine(i);
				pageLineSetXPosition(pageLine, page.x, page.width, page.xOffset, x, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
			}
		page.x = x;
		if (xOffset != null) page.xOffset = xOffset;
		if (yOffset != null) page.yOffset = yOffset;
	}
	
	public function pageSetYPosition(page:Page<$styleType>, y:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;	
		if (yOffset != null) _setPagePosSizeOffset(page, _SET_POS, null, y, xOffset, yOffset, addRemoveGlyphes);
		else
			for (i in 0...page.length) {
				var pageLine = page.getPageLine(i);
				pageLineSetYPosition(pageLine, page.x, page.width, page.xOffset, pageLine.y + y - page.y , xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
			}
		page.y = y;
		if (xOffset != null) page.xOffset = xOffset;
		if (yOffset != null) page.yOffset = yOffset;
	}
	
	public function pageSetPositionSize(page:Page<$styleType>, x:Float, y:Float, width:Float, height:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;
		page.height = height;
		if (page.width != width) {
			page.width = width;
			_setPagePosSizeOffset(page, _SET_POS_SIZE, x, y, xOffset, (yOffset != null) ? yOffset : 0, addRemoveGlyphes);
		} 
		else _setPagePosSizeOffset(page, _SET_POS, x, y, xOffset, (yOffset != null) ? yOffset : 0, addRemoveGlyphes);
		page.x = x;
		page.y = y;
		if (xOffset != null) page.xOffset = xOffset;
		if (yOffset != null) page.yOffset = yOffset;
	}
	
	public function pageSetSize(page:Page<$styleType>, width:Float, height:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;
		page.height = height;
		if (page.width != width) {
			page.width = width;
			if (yOffset != null) _setPagePosSizeOffset(page, _SET_POS_SIZE, page.x, page.y, xOffset, yOffset, addRemoveGlyphes);
			else _setPagePosSizeOffset(page, _SET_SIZE, null, page.y, xOffset, 0, addRemoveGlyphes);
		} 
		else _setPagePosSizeOffset(page, _SET_POS, null, page.y, xOffset, (yOffset != null) ? yOffset : 0, addRemoveGlyphes);		
		if (xOffset != null) page.xOffset = xOffset;
		if (yOffset != null) page.yOffset = yOffset;
	}
	
	public function pageSetOffset(page:Page<$styleType>, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;		
		if (yOffset != null) _setPagePosSizeOffset(page, _SET_POS, null, page.y, xOffset, yOffset, addRemoveGlyphes);
		else
			for (i in 0...page.length) {
				var pageLine = page.getPageLine(i);
				pageLineSetOffset(pageLine, page.x, page.width, page.xOffset, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
			}
		if (xOffset != null) page.xOffset = xOffset;
		if (yOffset != null) page.yOffset = yOffset;
	}
	
	public function pageSetXOffset(page:Page<$styleType>, xOffset:Float, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;		
		for (i in 0...page.length) {
			var pageLine = page.getPageLine(i);
			pageLineSetOffset(pageLine, page.x, page.width, page.xOffset, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
		}
		page.xOffset = xOffset;
	}
	
	public function pageSetYOffset(page:Page<$styleType>, yOffset:Float, addRemoveGlyphes:Bool = true) {
		page.updateLineFrom = 0;
		page.updateLineTo = page.length;		
		_setPagePosSizeOffset(page, _SET_POS, null, page.y, null, yOffset, addRemoveGlyphes);
		page.yOffset = yOffset;
	}
	
	static inline var _SET_POS = 0;
	static inline var _SET_POS_SIZE = 1;
	static inline var _SET_SIZE = 2;
	
	inline function _setPagePosSizeOffset(page:Page<$styleType>, howToSet:Int, x:Null<Float>, y:Float, ?xOffset:Null<Float>, yOffset:Float, addRemoveGlyphes:Bool)
	{
		var visibleLineFrom = page.visibleLineFrom;
		var visibleLineTo = page.visibleLineTo;
		
		for (i in 0...page.length)
		{
			var pageLine = page.getPageLine(i);
			
			if (howToSet == _SET_POS_SIZE) pageLineSetPositionSize( pageLine, page.x, page.width, page.xOffset, x, yOffset + pageLine.y + y - page.y, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
			else if (howToSet == _SET_SIZE) pageLineSetSize( pageLine, page.x, page.width, page.xOffset, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
			else if (howToSet == _SET_POS) {
				if (x != null) pageLineSetPosition( pageLine, page.x, page.width, page.xOffset, x, yOffset + pageLine.y + y - page.y, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
				else pageLineSetYPosition(pageLine, page.x, page.width, page.xOffset, yOffset + pageLine.y + y - page.y, xOffset, addRemoveGlyphes && (page.visibleLineFrom <= i && i < page.visibleLineTo));
			}
			
			// add or remove if inside visible area
			if (pageLine.y + pageLine.lineHeight >= y)
			{	
				if (pageLine.y < y + page.height) {
					if (i < page.visibleLineFrom || i >= page.visibleLineTo) {
						if (addRemoveGlyphes) pageLineAdd(pageLine);
						if (visibleLineFrom > i) visibleLineFrom = i;
						if (visibleLineTo < i + 1) visibleLineTo = i + 1;
					}
				} 
				else {
					if (addRemoveGlyphes && i >= page.visibleLineFrom && i < page.visibleLineTo) pageLineRemove(pageLine);
					if (visibleLineTo > i) visibleLineTo = i;
				}
			}
			else {
				if (addRemoveGlyphes && i >= page.visibleLineFrom && i < page.visibleLineTo) pageLineRemove(pageLine);
				visibleLineFrom = i + 1;
			}	
		}
		
		page.visibleLineFrom = visibleLineFrom;
		page.visibleLineTo = visibleLineTo;
	}
	

	public inline function pageInsertLine(page:Page<$styleType>, lineNumber:Int, chars:String, glyphStyle:$styleType = null)
	{
		
	}

	//public inline function pageAppendLine

	public inline function pageDeleteLine(page:Page<$styleType>, lineNumber:Int)
	{
		
	}

	public inline function pageSetLine(page:Page<$styleType>, lineNumber:Int, chars:String, glyphStyle:$styleType = null)
	{
		
	}
	
	public function pageUpdate(page:Page<$styleType>, fromLine:Null<Int> = null, toLine:Null<Int> = null)
	{
		if (fromLine != null) page.updateLineFrom = fromLine;
		if (toLine != null) page.updateLineTo = toLine;
		
		//trace("visibleLine: " + page.visibleLineFrom+ "-" +page.visibleLineTo);
		//trace("updateLine : " +  page.updateLineFrom + "-" +page.updateLineTo);
		
		if (page.updateLineTo > 0 )
		{
			if (page.visibleLineFrom > page.updateLineFrom) page.updateLineFrom = page.visibleLineFrom;
			if (page.visibleLineTo < page.updateLineTo) page.updateLineTo = page.visibleLineTo;
			//trace("update from Line " + page.updateLineFrom + " to " +page.updateLineTo);
			
			for (i in page.updateLineFrom...page.updateLineTo) pageLineUpdate(page.getPageLine(i));

			page.updateLineFrom = 0x1000000;
			page.updateLineTo = 0;
		} 
		//else trace("nothing to update");

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