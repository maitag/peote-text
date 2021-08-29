package peote.text;

#if !macro
@:genericBuild(peote.text.Line.LineMacro.build("Line"))
class Line<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import peote.text.util.Macro;

class LineMacro
{
	static public function build(name:String):ComplexType return Macro.build(name, buildClass);
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>):ComplexType
	{
		className += Macro.classNameExtension(styleName, styleModule);
		
		if ( Macro.isNotGenerated(className) )
		{
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			var glyphType = Glyph.GlyphMacro.buildClass("Glyph", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			
			var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
			var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
			
			var c = macro
			
// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------

class $className
{
	@:allow(peote.text) public var x(default, null):Float = 0.0;
	@:allow(peote.text) public var y(default, null):Float = 0.0;
	public var xOffset:Float = 0.0;
	public var yOffset:Float = 0.0;				
	public var maxX:Float = 0xffff;
	//public var maxY:Float = 0xffff;
	
	@:allow(peote.text) public var fullWidth(default, null):Float = 0.0;
	//@:allow(peote.text) public var fullHeight(default, null):Float = 0.0; // TODO
	
	public var lineHeight:Float = 0.0;
	public var height:Float = 0.0; // height (highest glyph)
	public var base:Float = 0.0;   // baseline for font
	
	
	//public var xDirection:Int = 1;  // <- TODO: better later with LineStyle !!!
	//public var yDirection:Int = 0;
	public var length(get, never):Int; // number of glyphes
	public inline function get_length():Int return glyphes.length;
	
	
	// TODO: optimize for neko/hl/cpp
	var glyphes = new Array<$glyphType>();
	
	public inline function getGlyph(i:Int):$glyphType return glyphes[i];
	@:allow(peote.text) inline function setGlyph(i:Int, glyph:$glyphType) glyphes[i] = glyph;
	@:allow(peote.text) inline function pushGlyph(glyph:$glyphType) glyphes.push(glyph);
	@:allow(peote.text) inline function insertGlyph(pos:Int, glyph:$glyphType) glyphes.insert(pos, glyph);
	
	@:allow(peote.text) inline function splice(pos:Int, len:Int):Array<$glyphType> return glyphes.splice(pos, len);
	@:allow(peote.text) inline function resize(newLength:Int) {
		//TODO HAXE 4 lines.resize(newLength);
		glyphes.splice(newLength, glyphes.length - newLength);
	}
	@:allow(peote.text) inline function append(a:Array<$glyphType>) {
		glyphes = glyphes.concat(a);
	}
	
	@:allow(peote.text) var updateFrom:Int = 0x1000000;
	@:allow(peote.text) var updateTo:Int = 0;
	@:allow(peote.text) public var visibleFrom(default, null):Int = 0;
	@:allow(peote.text) public var visibleTo(default, null):Int = 0;
	
	public function new() {}
}
			
// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------
			
			Context.defineModule(classPackage.concat([className]).join('.'),[c]);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
}
#end
