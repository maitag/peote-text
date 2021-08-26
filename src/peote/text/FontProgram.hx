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
	public var font:peote.text.Font<$styleType>; // TODO peote.text.Font<$styleType>
	public var fontStyle:$styleType;
	
	public var penX:Float = 0.0;
	public var penY:Float = 0.0;
	
	public var isMasked(default, null) = false;
	var maskProgram:peote.view.Program;
	var maskBuffer:peote.view.Buffer<peote.text.MaskElement>;
	
	var prev_charcode = -1;
	
	var _buffer:peote.view.Buffer<$glyphType>;
	
	public function new(font:peote.text.Font<$styleType>, fontStyle:$styleType, isMasked:Bool = false)
	{
		_buffer = new peote.view.Buffer<$glyphType>(1024,1024,true);
		super(_buffer);
		
		if (isMasked) enableMasking();

		setFont(font);
		setFontStyle(fontStyle);
	}
	
	// -----------------------------------------
	// ----------- Mask Program  ---------------
	// -----------------------------------------
	public function enableMasking() {
			isMasked = true;
			maskBuffer = new peote.view.Buffer<peote.text.MaskElement>(16, 16, true);
			maskProgram = new peote.view.Program(maskBuffer);
			maskProgram.mask = peote.view.Mask.DRAW;
			maskProgram.colorEnabled = false;
			mask = peote.view.Mask.USE;			
	}
	
	override public function addToDisplay(display:peote.view.Display, ?atProgram:peote.view.Program, addBefore:Bool=false)
	{
		super.addToDisplay(display, atProgram, addBefore);
		if (isMasked) maskProgram.addToDisplay(display, this, true);
	}
	
	override public function removeFromDisplay(display:peote.view.Display):Void
	{
		super.removeFromDisplay(display);
		if (isMasked) maskProgram.removeFromDisplay(display);
	}
	
	public inline function createMask(x:Int, y:Int, w:Int, h:Int):peote.text.MaskElement {
		var maskElement = new peote.text.MaskElement(x, y, w, h);
		maskBuffer.addElement(maskElement);
		return maskElement;
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
	
	inline function kerningOffset(prev_glyph:$glyphType, glyph:$glyphType, kerning:Array<Array<Float>>):Float
	{
		${switch (glyphStyleHasMeta.packed)
		{	case true: macro // ------- Gl3Font -------
			{	
				if (font.kerning && prev_glyph != null) 
				{	trace("kerning: ", prev_glyph.char, glyph.char, " -> " + kerning[prev_glyph.char][glyph.char]);
					${switch (glyphStyleHasField.local_width) {
						case true: macro return kerning[prev_glyph.char][glyph.char] * (glyph.width + prev_glyph.width)/2;
						default: switch (glyphStyleHasField.width) {
							case true: macro return kerning[prev_glyph.char][glyph.char] * fontStyle.width;
							default: macro return kerning[prev_glyph.char][glyph.char] * font.config.width;
					}}}
				} else return 0.0;
			}
			default: macro { // ------- simple font -------
				return 0.0;
			}
		}}					
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
				glyph.tx = charData.metric.u;//-2; // TODO: offsets for THICK letters
				glyph.ty = charData.metric.v;//-2;
				glyph.tw = charData.metric.w;//+4;
				glyph.th = charData.metric.h;//+4;							
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
	// TODO: put at a baseline and special for simple font
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
	
	// -----------------------------------------
	// ---------------- Lines ------------------
	// -----------------------------------------
	
	public inline function createLine(chars:String, x:Float=0, y:Float=0, glyphStyle:Null<$styleType> = null):$lineType
	{
		var line = new peote.text.Line<$styleType>();
		setLine(line, chars, x, y, glyphStyle);
		return line;
	}
	
	public inline function addLine(line:$lineType):Void
	{
		for (i in line.visibleFrom...line.visibleTo) addGlyph(line.getGlyph(i));
	}
	
	public inline function removeLine(line:$lineType)
	{
		for (i in line.visibleFrom...line.visibleTo) removeGlyph(line.getGlyph(i));
	}
	
	public inline function setLine(line:$lineType, chars:String, x:Float=0, y:Float=0, glyphStyle:$styleType = null):Bool
	{
		//trace("setLine");
		
		line.x = x;
		line.y = y;
		
		x += line.xOffset;					
		y += line.yOffset;					
			
		if (line.length == 0)
		{
			if (_lineAppend(line, chars, x, y, null, glyphStyle, true) == 0) return false else return true;
		}
		else
		{
			var prev_glyph:$glyphType = null;
			var i = 0;
			var ret = true;
			var charData:$charDataType = null;
			
			var visibleFrom:Int = 0;
			var visibleTo:Int = 0;
			
			peote.text.util.StringUtils.iter(chars, function(charcode)
			{
				charData = getCharData(charcode);
				if (charData != null)
				{
					if (i == line.length) { // append
						line.pushGlyph(new peote.text.Glyph<$styleType>());
						glyphSetStyle(line.getGlyph(i), glyphStyle);
						setCharcode(line.getGlyph(i), charcode, charData);
						setSize(line.getGlyph(i), charData);
						${switch (glyphStyleHasMeta.packed) {
							case true: macro x += kerningOffset(prev_glyph, line.getGlyph(i), charData.fontData.kerning);
							default: macro {}
						}}
						setPosition(line.getGlyph(i), charData, x, y);

						if (line.getGlyph(i).x + ${switch(glyphStyleHasMeta.packed) {case true: macro line.getGlyph(i).w; default: macro line.getGlyph(i).width;}} >= line.x) {														
							if (line.getGlyph(i).x < line.maxX) {
								_buffer.addElement(line.getGlyph(i));
								visibleTo ++;
							}
						}
						else {
							visibleFrom ++;
							visibleTo ++;
						}

						x += nextGlyphOffset(line.getGlyph(i), charData);
					}
					else { // set over
						if (glyphStyle != null) glyphSetStyle(line.getGlyph(i), glyphStyle);
						setCharcode(line.getGlyph(i), charcode, charData);
						setSize(line.getGlyph(i), charData);
						${switch (glyphStyleHasMeta.packed) {
							case true: macro x += kerningOffset(prev_glyph, line.getGlyph(i), charData.fontData.kerning);
							default: macro {}
						}}
						setPosition(line.getGlyph(i), charData, x, y);
				
						if (line.getGlyph(i).x + ${switch(glyphStyleHasMeta.packed) {case true: macro line.getGlyph(i).w; default: macro line.getGlyph(i).width;}} >= line.x) {														
							if (line.getGlyph(i).x < line.maxX) {
								if (i < line.visibleFrom || i >= line.visibleTo) _buffer.addElement(line.getGlyph(i));
								visibleTo ++;
							} else if (i < line.visibleTo) _buffer.removeElement(line.getGlyph(i));
						}
						else {
							if (i >= line.visibleFrom) _buffer.removeElement(line.getGlyph(i));
							visibleFrom ++;
							visibleTo ++;
						}
						
						x += nextGlyphOffset(line.getGlyph(i), charData);
					}
					prev_glyph = line.getGlyph(i);
					i++;
				}
				else ret = false;
			});
									
			if (line.length > i) {
				lineDeleteChars(line, i);
				for (j in Std.int(Math.max(i, line.visibleFrom))...Std.int(Math.min(line.length, line.visibleTo))) {
					removeGlyph(line.getGlyph(j));
				}
				line.resize(i);							
			}
			line.updateFrom = 0;
			line.updateTo = i;
			
			line.visibleFrom = visibleFrom;
			line.visibleTo = visibleTo;
			
			line.fullWidth = x - line.x - line.xOffset;
			
			_setNewLineMetric(line, prev_glyph, charData);
			return ret;
		}
	}
	
	inline function _setNewLineMetric(line:$lineType, glyph:$glyphType, charData:$charDataType) {
		if (glyph != null) {
			${switch (glyphStyleHasMeta.packed) {
				case true: macro {
					var h = ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
					line.height = h * charData.fontData.height;
					line.lineHeight = h * charData.fontData.lineHeight;
					line.base = h * charData.fontData.base;
					//trace("line metric:", line.lineHeight, line.height, line.base);
				}
				default: macro {
					var h = ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
					line.height = h;
					line.lineHeight = h * charData.height;
					line.base = h * charData.base;
					//trace("line metric:", line.lineHeight, line.height, line.base);
				}
			}}
		}
	}
	
	inline function _baseLineOffset(line:$lineType, glyph:$glyphType, charData:$charDataType):Float {
		if (glyph != null) {
			${switch (glyphStyleHasMeta.packed) {
				case true: macro {
					return line.base - charData.fontData.base * ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
				}
				default: macro {
					return line.base - charData.base * ${switch (glyphStyleHasField.local_height) {
						case true: macro glyph.height;
						default: switch (glyphStyleHasField.height) {
							case true: macro fontStyle.height;
							default: macro font.config.height;
					}}}
				}
			}}
		} else return 0;
	}
	
	// ----------- change Line Style and Position ----------------
	
	public function lineSetStyle(line:$lineType, glyphStyle:$styleType, from:Int = 0, to:Null<Int> = null):Float
	{
		if (to == null) to = line.length;
		//else if (to <= from) throw('lineSetStyle parameter "from" has to be greater then "to"');
		
		if (from < line.updateFrom) line.updateFrom = from;
		if (to > line.updateTo) line.updateTo = to;
		
		//var prev_glyph:peote.text.Glyph<$styleType> = null;
		var prev_glyph:$glyphType = null;
		
		var x = line.x + line.xOffset;
		var y = line.y + line.yOffset;
		
		if (from > 0) {
			x = rightGlyphPos(line.getGlyph(from - 1), getCharData(line.getGlyph(from - 1).char));
			prev_glyph = line.getGlyph(from - 1);
		}
		var x_start = x;
		
		// first
		line.getGlyph(from).setStyle(glyphStyle);
		var charData = getCharData(line.getGlyph(from).char);
		
		y += _baseLineOffset(line, line.getGlyph(from), charData);
		
		setPosition(line.getGlyph(from), charData, x, y);
		x += nextGlyphOffset(line.getGlyph(from), charData);
		prev_glyph = line.getGlyph(from);
		
		for (i in from+1...to)
		{
			line.getGlyph(i).setStyle(glyphStyle);
			charData = getCharData(line.getGlyph(i).char);
			${switch (glyphStyleHasMeta.packed) {
				case true: macro x += kerningOffset(prev_glyph, line.getGlyph(i), charData.fontData.kerning);
				default: macro {}
			}}
			setPosition(line.getGlyph(i), charData, x, y);
			x += nextGlyphOffset(line.getGlyph(i), charData);
			prev_glyph = line.getGlyph(i);
		}

		x_start = x - x_start;
		if (to < line.length) // rest
		{
			${switch (glyphStyleHasMeta.packed) {
				case true: macro x += kerningOffset(prev_glyph, line.getGlyph(to), charData.fontData.kerning);
				default: macro {}
			}}
			var offset = x - leftGlyphPos(line.getGlyph(to), getCharData(line.getGlyph(to).char));
			if (offset != 0.0) {
				line.updateTo = line.length;
				_setLinePositionOffset(line, offset, from, to, line.updateTo);
			} else _setLinePositionOffset(line, offset, from, to, to);
		} else _setLinePositionOffset(line, 0, from, to, to);
		
		return x_start;
	}
	
	// TODO: optimized lineSetXPosition and lineSetYPosition
	public function lineSetPosition(line:$lineType, xNew:Float, yNew:Float)
	{
		line.updateFrom = 0;
		line.updateTo = line.length;
		for (i in 0...line.updateTo) {
			line.getGlyph(i).x += xNew - line.x;
			line.getGlyph(i).y += yNew - line.y;
		}
		line.x = xNew;
		line.y = yNew;
	}
	
	inline function _setLinePositionOffset(line:$lineType, deltaX:Float, from:Int, withDelta:Int, to:Int, updateFullWidth=true)
	{
		var visibleFrom = line.visibleFrom;
		var visibleTo = line.visibleTo;

		for (i in from...to) {
			
			if (i >= withDelta) line.getGlyph(i).x += deltaX; // OPTIMIZATION: new bool param for DCE
			
			if (line.getGlyph(i).x + ${switch(glyphStyleHasMeta.packed) {case true: macro line.getGlyph(i).w; default: macro line.getGlyph(i).width; }} >= line.x)
			{	
				if (line.getGlyph(i).x < line.maxX) {
					if (i < line.visibleFrom || i >= line.visibleTo) {
						//trace("addElement",i);
						_buffer.addElement(line.getGlyph(i));
						if (visibleFrom > i) visibleFrom = i;
						if (visibleTo < i + 1) visibleTo = i + 1;
					} //else trace("-- already added", i);
				} 
				else {
					if (i >= line.visibleFrom && i < line.visibleTo) {
						//trace("removeElement",i);
						_buffer.removeElement(line.getGlyph(i));
					} //else trace("-- already removed", i);
					if (visibleTo > i) visibleTo = i;
				}
			}
			else {
				if (i >= line.visibleFrom && i < line.visibleTo) {
					//trace("removeElement Front", i);
					_buffer.removeElement(line.getGlyph(i));
				} //else trace("-- already removed Front", i);
				visibleFrom = i + 1;
			}
			//trace("from " + visibleFrom, "To " + visibleTo);
		}
		line.visibleFrom = visibleFrom;
		line.visibleTo = visibleTo;
		
		if (updateFullWidth) line.fullWidth += deltaX;
	}
	

	
	// ------------ set chars  ---------------
	
	public function lineSetChar(line:$lineType, charcode:Int, position:Int=0, glyphStyle:$styleType = null):Float
	{
		var charData = getCharData(charcode);
		if (charData != null)
		{
			if (position < line.updateFrom) line.updateFrom = position;
			if (position + 1 > line.updateTo) line.updateTo = position + 1;
			
			var prev_glyph:$glyphType = null;
			
			var x = line.x + line.xOffset;
			var y = line.y + line.yOffset;
			
			if (position > 0) {
				x = rightGlyphPos(line.getGlyph(position - 1), getCharData(line.getGlyph(position - 1).char));
				prev_glyph = line.getGlyph(position - 1);
			}
			var x_start = x;
			
			if (glyphStyle != null) {
				glyphSetStyle(line.getGlyph(position), glyphStyle);
				y += _baseLineOffset(line, line.getGlyph(position), charData);
			}
			setCharcode(line.getGlyph(position), charcode, charData);
			setSize(line.getGlyph(position), charData);
			${switch (glyphStyleHasMeta.packed) {
				case true: macro x += kerningOffset(prev_glyph, line.getGlyph(position), charData.fontData.kerning);
				default: macro {}
			}}
			setPosition(line.getGlyph(position), charData, x, y);
			
			x += nextGlyphOffset(line.getGlyph(position), charData);
			
			x_start = x - x_start;
			if (position+1 < line.length) // rest
			{	
				${switch (glyphStyleHasMeta.packed) {
					case true: macro x += kerningOffset(line.getGlyph(position), line.getGlyph(position+1), charData.fontData.kerning);
					default: macro {}
				}}
				var offset = x - leftGlyphPos(line.getGlyph(position+1), getCharData(line.getGlyph(position+1).char));
				if (offset != 0.0) {
					line.updateTo = line.length;
					_setLinePositionOffset(line, offset, position, position + 1, line.updateTo);
				} else _setLinePositionOffset(line, offset, position, position + 1, position + 1);
			} else _setLinePositionOffset(line, 0, position, position + 1, position + 1);
			
			return x_start;
		} 
		else return 0;					
	}
	
	public function lineSetChars(line:$lineType, chars:String, position:Int=0, glyphStyle:$styleType = null):Float
	{
		//if (position < line.updateFrom) line.updateFrom = position;
		//if (position + chars.length > line.updateTo) line.updateTo = Std.int(Math.min(position + chars.length, line.length));
		
		var prev_glyph:$glyphType = null;
		var x = line.x + line.xOffset;
		var y = line.y + line.yOffset;
		
		if (position > 0) {
			x = rightGlyphPos(line.getGlyph(position - 1), getCharData(line.getGlyph(position - 1).char));
			prev_glyph = line.getGlyph(position - 1);
		}
		var x_start = x;

		var i = position;
		var charData:$charDataType = null;
		
		peote.text.util.StringUtils.iter(chars, function(charcode)
		{
			if (i < line.length) 
			{							
				charData = getCharData(charcode);
				if (charData != null)
				{
					if (glyphStyle != null) {
						glyphSetStyle(line.getGlyph(i), glyphStyle);
						if (i == position) // first
						{					
							y += _baseLineOffset(line, line.getGlyph(i), charData);
						}
					}
					setCharcode(line.getGlyph(i), charcode, charData);
					setSize(line.getGlyph(i), charData);
					${switch (glyphStyleHasMeta.packed) {
						case true: macro x += kerningOffset(prev_glyph, line.getGlyph(i), charData.fontData.kerning);
						default: macro {}
					}}
					setPosition(line.getGlyph(i), charData, x, y);
					x += nextGlyphOffset(line.getGlyph(i), charData);
					prev_glyph = line.getGlyph(i);
					i++;
				}
			}
			else {
				var offset = lineInsertChar(line, charcode, i, glyphStyle); // TODO: use append
				if (offset > 0) {
					x += offset;
					i++;
				}
			}
		});
		
		if (position < line.updateFrom) line.updateFrom = position;
		if (position + i > line.updateTo) line.updateTo = Std.int(Math.min(position + i, line.length));
		
		x_start = x - x_start;
		if (i < line.length) // rest
		{
			${switch (glyphStyleHasMeta.packed) {
				case true: macro x += kerningOffset(line.getGlyph(i-1), line.getGlyph(i), charData.fontData.kerning);
				default: macro {}
			}}
			var offset = x - leftGlyphPos(line.getGlyph(i), getCharData(line.getGlyph(i).char));
			if (offset != 0.0) {
				line.updateTo = line.length;
				_setLinePositionOffset(line, offset, position, i, line.updateTo);
			} else _setLinePositionOffset(line, offset, position, i, i);
		} else _setLinePositionOffset(line, 0, position, i, i);
	
		return x_start;
	}
	
	
	
	// ------------- inserting chars ---------------------

	
	public function lineInsertChar(line:$lineType, charcode:Int, position:Int = 0, glyphStyle:$styleType = null):Float
	{
		var charData = getCharData(charcode);
		if (charData != null)
		{
			var prev_glyph:$glyphType = null;
			
			var x = line.x + line.xOffset;
			var y = line.y + line.yOffset;
			
			if (position > 0) {
				x = rightGlyphPos(line.getGlyph(position - 1), getCharData(line.getGlyph(position - 1).char));
				prev_glyph = line.getGlyph(position - 1);
			}
			var x_start = x;
			
			var glyph = new peote.text.Glyph<$styleType>();
			
			glyphSetStyle(glyph, glyphStyle);
			
			y += _baseLineOffset(line, glyph, charData);
			
			setCharcode(glyph, charcode, charData);
			setSize(glyph, charData);
			${switch (glyphStyleHasMeta.packed) {
				case true: macro x += kerningOffset(prev_glyph, glyph, charData.fontData.kerning);
				default: macro {}
			}}
			setPosition(glyph, charData, x, y);						
			
			x += nextGlyphOffset(glyph, charData);
			
			if (position < line.length) {
				if (position < line.updateFrom) line.updateFrom = position+1;
				line.updateTo = line.length + 1;
				
//TODO: KERNING 
				
				_setLinePositionOffset(line, x - x_start, position, position, line.length);
			}
			else line.fullWidth += x - x_start;
			
			line.insertGlyph(position, glyph);
			
			if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width; }} >= line.x)
			{
				if (glyph.x < line.maxX) {
					_buffer.addElement(glyph);
					line.visibleTo++;
				}
			} 
			else {
				line.visibleFrom++;
				line.visibleTo++;
			}
			
			return x - x_start;
		}
		else return 0;
	}
	
	
	public function lineInsertChars(line:$lineType, chars:String, position:Int = 0, glyphStyle:$styleType = null):Float 
	{					
		var prev_glyph:$glyphType = null;
		var x = line.x + line.xOffset;
		var y = line.y + line.yOffset;
		if (position > 0) {
			x = rightGlyphPos(line.getGlyph(position - 1), getCharData(line.getGlyph(position - 1).char));
			prev_glyph = line.getGlyph(position - 1);
		}
		
		var rest = line.splice(position, line.length - position);
		
		if (rest.length > 0) {
			var oldFrom = line.visibleFrom - line.length;
			var oldTo = line.visibleTo - line.length;
			if (line.visibleFrom > line.length) line.visibleFrom = line.length;
			if (line.visibleTo > line.length) line.visibleTo = line.length;
			var deltaX = _lineAppend(line, chars, x, y, prev_glyph, glyphStyle);
//TODO: deltaX += KERNING 
//TODO: line.fullWidth += 
			if (deltaX != 0.0) // TODO
			{
				if (line.length < line.updateFrom) line.updateFrom = line.length;
				
				for (i in 0...rest.length) {
					rest[i].x += deltaX;
					
					if (rest[i].x + ${switch(glyphStyleHasMeta.packed) {case true: macro rest[i].w; default: macro rest[i].width; }} >= line.x)
					{	
						if (rest[i].x < line.maxX) {
							if (i < oldFrom || i >= oldTo) {
								_buffer.addElement(rest[i]);
							}
							line.visibleTo++;
						} else if (i >= oldFrom && i < oldTo) {
							_buffer.removeElement(rest[i]);
						}
					}
					else {
						if (i >= oldFrom && i < oldTo) {
							_buffer.removeElement(rest[i]);
						}
						line.visibleFrom++;
						line.visibleTo++;
					}
				}
					
				//line.fullWidth += deltaX;
				
				line.append(rest);
				line.updateTo = line.length;
			} 
			else {
				line.visibleFrom = oldFrom + line.length;
				line.visibleTo = oldTo + line.length;							
				line.append(rest);
			}
			return deltaX;
		}
		else return _lineAppend(line, chars, x, y, prev_glyph, glyphStyle);
	}
	
	

	// ------------- appending chars ---------------------
	
	
	public function lineAppendChars(line:$lineType, chars:String, glyphStyle:$styleType = null):Float
	{					
		var prev_glyph:$glyphType = null;
		var x = line.x + line.xOffset;
		var y = line.y + line.yOffset;
		if (line.length > 0) {
			x = rightGlyphPos(line.getGlyph(line.length - 1), getCharData(line.getGlyph(line.length - 1).char));
			prev_glyph = line.getGlyph(line.length - 1);
		}
		return _lineAppend(line, chars, x, y, prev_glyph, glyphStyle);
	}
	
	public inline function _lineAppend(line:$lineType, chars:String, x:Float, y:Float, prev_glyph:peote.text.Glyph<$styleType>, glyphStyle:$styleType, setNewLineMetrics:Bool = false):Float
	{
		var first = ! setNewLineMetrics;
		var glyph:$glyphType = null;
		var charData:$charDataType = null;
		
		var x_start = x;
		
		peote.text.util.StringUtils.iter(chars, function(charcode)
		{
			charData = getCharData(charcode);
			if (charData != null)
			{
				glyph = new peote.text.Glyph<$styleType>();
				line.pushGlyph(glyph);
				glyphSetStyle(glyph, glyphStyle);
				if (first) {
					first = false;
					y += _baseLineOffset(line, glyph, charData);
				}
				setCharcode(glyph, charcode, charData);
				setSize(glyph, charData);
				${switch (glyphStyleHasMeta.packed) {
					case true: macro x += kerningOffset(prev_glyph, glyph, charData.fontData.kerning);
					default: macro {}
				}}
				setPosition(glyph, charData, x, y);
				
				if (glyph.x + ${switch(glyphStyleHasMeta.packed) {case true: macro glyph.w; default: macro glyph.width;}} >= line.x)  {
					if (glyph.x < line.maxX)	{
						_buffer.addElement(glyph);
						line.visibleTo ++;
					}
				}
				else {
					line.visibleFrom ++;
					line.visibleTo ++;
				}

				x += nextGlyphOffset(glyph, charData);

				prev_glyph = glyph;
			}
		});

		//line.fullWidth = x - line.x - line.xOffset;
		line.fullWidth += x - x_start;
		
		if (setNewLineMetrics) _setNewLineMetric(line, prev_glyph, charData);

		return x - x_start;
	}
	
	

	// ------------- deleting chars ---------------------
	
	
	public function lineDeleteChar(line:$lineType, position:Int = 0):Float
	{
		if (position >= line.visibleFrom && position < line.visibleTo) {
			removeGlyph(line.getGlyph(position));
		}
		
		var offset = _lineDeleteCharsOffset(line, position, position + 1);
		
		if (position < line.visibleFrom) {
			line.visibleFrom--; line.visibleTo--;
		} 
		else if (position < line.visibleTo) {
			line.visibleTo--;
		}
		
		line.splice(position, 1);
		
		return offset;
	}
	
	public function lineCutChars(line:$lineType, from:Int = 0, to:Null<Int> = null):String
	{
		if (to == null) to = line.length;
		var cut = "";
		for (i in ((from < line.visibleFrom) ? line.visibleFrom : from)...((to < line.visibleTo) ? to : line.visibleTo)) {
			cut += String.fromCharCode(line.getGlyph(i).char);
			removeGlyph(line.getGlyph(i));
		}
		_lineDeleteChars(line, from, to);
		return cut;
	}
	
	public function lineDeleteChars(line:$lineType, from:Int = 0, to:Null<Int> = null):Float
	{
		if (to == null) to = line.length;
		for (i in ((from < line.visibleFrom) ? line.visibleFrom : from)...((to < line.visibleTo) ? to : line.visibleTo)) {
			removeGlyph(line.getGlyph(i));
		}
		return _lineDeleteChars(line, from, to);
	}
	
	inline function _lineDeleteChars(line:$lineType, from:Int, to:Int):Float
	{
		var offset = _lineDeleteCharsOffset(line, from, to);
		
		if (from < line.visibleFrom) {
			line.visibleFrom = (to < line.visibleFrom) ? line.visibleFrom - to + from : from;
			line.visibleTo = (to < line.visibleTo) ? line.visibleTo - to + from : from;
		}
		else if (from < line.visibleTo) {
			line.visibleTo = (to < line.visibleTo) ? line.visibleTo - to + from : from;
		}
		
		line.splice(from, to - from);
		
		return offset;
	}
	
	inline function _lineDeleteCharsOffset(line:$lineType, from:Int, to:Int):Float
	{
		var offset:Float = 0.0;
		if (to < line.length) 
		{
			var charData = getCharData(line.getGlyph(to).char);
			if (from == 0) offset = line.x + line.xOffset - leftGlyphPos(line.getGlyph(to), charData);
			else {
				offset = rightGlyphPos(line.getGlyph(from-1), getCharData(line.getGlyph(from-1).char)) - leftGlyphPos(line.getGlyph(to), charData);
				${switch (glyphStyleHasMeta.packed) {
					case true: macro offset -= kerningOffset(line.getGlyph(from-1), line.getGlyph(to), charData.fontData.kerning);
					default: macro {}
				}}
			}
			if (line.updateFrom > from) line.updateFrom = from;
			line.updateTo = line.length - to + from;
			_setLinePositionOffset(line, offset, to, to, line.length);
		}
		else 
		{ 	// delete from end
			if ( line.updateFrom >= line.length - to + from ) {
				line.updateFrom = 0x1000000;
				line.updateTo = 0;
			}
			else if ( line.updateTo > line.length - to + from) {
				line.updateTo = line.length - to + from;
			}
			
			if (from != 0) 
				offset = rightGlyphPos(line.getGlyph(from - 1), getCharData(line.getGlyph(from - 1).char)) - (line.x + line.xOffset + line.fullWidth);
			else offset = -line.fullWidth;

			line.fullWidth += offset;
		}
		return offset;
	}
	
	
	// ------------- get glyph index at x position (for mouse-selecting) ---------------
	
	public function lineGetCharPosition(line:$lineType, position:Int):Float
	{
		if (position == 0)
			return line.x + line.xOffset;
		else if (position < line.length)
			return leftGlyphPos(line.getGlyph(position), getCharData(line.getGlyph(position).char));
		else
			return rightGlyphPos(line.getGlyph(line.length-1), getCharData(line.getGlyph(line.length-1).char));
	}
					
	public function lineSetXOffset(line:$lineType, xOffset:Float)
	{
		var offset = xOffset - line.xOffset;
		line.xOffset = xOffset;
		
		line.updateFrom = 0;
		line.updateTo = line.length;
		_setLinePositionOffset(line, offset, 0, 0, line.updateTo, false);
	}
	
	public function lineGetCharAtPosition(line:$lineType, xPosition:Float):Int
	{
		if (xPosition <= line.x) return 0;
		else if (xPosition >= line.maxX) return line.visibleTo;
		else 
		{
			${switch (glyphStyleHasMeta.packed)
			{
				case true: macro // ------- Gl3Font -------
				{
					// TODO: binary search
					var i:Int = line.visibleFrom;
					while (i < line.visibleTo && xPosition > line.getGlyph(i).x) i++;
					if (i == 0) return 0;
					var chardata = getCharData(line.getGlyph(i - 1).char);
					if ( xPosition < (leftGlyphPos(line.getGlyph(i - 1), chardata) + rightGlyphPos(line.getGlyph(i - 1), chardata)) / 2)
						return i-1;
					else return i;
				}
				default: macro // ------- simple font -------
				{
					${switch (glyphStyleHasField.local_width) {
						case true: macro {
							// TODO: binary search
							var i:Int = line.visibleFrom;
							while (i < line.visibleTo && xPosition > line.getGlyph(i).x) i++;
							if (i == 0) return 0;
							var chardata =  getCharData(line.getGlyph(i - 1).char);
							if ( xPosition < (leftGlyphPos(line.getGlyph(i - 1), chardata) + rightGlyphPos(line.getGlyph(i - 1), chardata)) / 2)
								return i-1;
							else return i;
						}
						default: switch (glyphStyleHasField.width) {
							case true: macro {
								return Math.round((xPosition - line.x - line.xOffset)/fontStyle.width);
							}
							default: macro {
								return Math.round((xPosition - line.x - line.xOffset)/font.config.width);
							}
					}}}
				}
			}}
		}
	}
	
	
	// ------------- update line ---------------------
	
	public function updateLine(line:$lineType, from:Null<Int> = null, to:Null<Int> = null)
	{
		if (from != null) line.updateFrom = from;
		if (to != null) line.updateTo = to;
		
		//trace("visibleFrom: " + line.visibleFrom+ "-" +line.visibleTo);
		//trace("updateFrom : " +  line.updateFrom + "-" +line.updateTo);
		if (line.updateTo > 0 )
		{
			if (line.visibleFrom > line.updateFrom) line.updateFrom = line.visibleFrom;
			if (line.visibleTo < line.updateTo) line.updateTo = line.visibleTo;
			//trace("update from " + line.updateFrom + " to " +line.updateTo);
			
			for (i in line.updateFrom...line.updateTo) updateGlyph(line.getGlyph(i));

			line.updateFrom = 0x1000000;
			line.updateTo = 0;
		} //else trace("nothing to update");
	}
	
	
	// -----------------------------------------
	// ---------------- Pages ------------------
	// -----------------------------------------

	public function createPage(chars:String, x:Float=0, y:Float=0, glyphStyle:Null<$styleType> = null):peote.text.Page<$styleType>
	{
		var page = new peote.text.Page<$styleType>();
		if (setPage(page, chars, x, y, glyphStyle)) return page else return null;
	}
	
	public function addPage(page:Page<$styleType>)
	{
		for (i in page.visibleFrom...page.visibleTo) addLine(page.getLine(i));
	}
	
	public function removePage(page:Page<$styleType>)
	{
		for (i in page.visibleFrom...page.visibleTo) removeLine(page.getLine(i));
	}
	
	var regLinesplit:EReg = ~/^(.*?)(\n|\r\n|\r)/; // TODO: optimize without regexp

	public inline function setPage(page:Page<$styleType>, chars:String, x:Float=0, y:Float=0, glyphStyle:$styleType = null):Bool
	{
		trace("setPage", chars);
		chars += "\n";
		// TODO: vertically masking
		// TODO: change linecreation to have tabs (alternatively into creation of a tab-char into font!)
		// TODO: wrap and wordwrap
		var i:Int = 0;
		
		while (regLinesplit.match(chars) && i < page.length) { // overwrite old lines
			trace("setLine", i, regLinesplit.matched(1));
			var line = page.getLine(i); // TODO: empty lines have no height !
			setLine( line, regLinesplit.matched(1), x, y, glyphStyle); // TODO: autoupdate
			updateLine(line);
			chars = regLinesplit.matchedRight();
			y += line.lineHeight;
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
