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
			var pageLinePath:TypePath =  { pack:classPackage, name:"PageLine" + Macro.classNameExtension(styleName, styleModule), params:[] };
			
			var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName);
			var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName);
			
			var c = macro
			
// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------

class $className
{
	@:allow(peote.text) public var x(default, null):Float = 0.0;
	
	@:allow(peote.text) public var offset(default, null):Float = 0.0;  // offset about how much the letters is shifted
	@:allow(peote.text) public var size(default, null):Float = 0xffff; // visible size of the line (in pixel)
	

	// ---------- from pageLine ------------
	@:allow(peote.text) var pageLine = new $pageLinePath();
	
	public var y(get, never):Float;
	public inline function get_y():Float return pageLine.y;
	
	public var textSize(get, never):Float; // size of all letters into line (in pixel)
	public inline function get_textSize():Float return pageLine.textSize;
	
	// metrics
	public var lineHeight(get, never):Float; // full line-height
	public inline function get_lineHeight():Float return pageLine.lineHeight;
	
	public var height(get, never):Float; // fontrange-baseline
	public inline function get_height():Float return pageLine.height;
	
	public var base(get, never):Float; // height of greatest letter into fontrange
	public inline function get_base():Float return pageLine.base;
	

	
	public var length(get, never):Int; // number of glyphes into line
	public inline function get_length():Int return pageLine.length;
	
	
	public inline function getGlyph(i:Int):$glyphType return pageLine.getGlyph(i);

	
	public var visibleFrom(get, never):Int;
	public inline function get_visibleFrom():Int return pageLine.visibleFrom;
	public var visibleTo(get, never):Int;
	public inline function get_visibleTo():Int return pageLine.visibleTo;

	public var updateFrom(get, never):Int;
	public inline function get_updateFrom():Int return pageLine.updateFrom;
	public var updateTo(get, never):Int;
	public inline function get_updateTo():Int return pageLine.updateTo;
	
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
