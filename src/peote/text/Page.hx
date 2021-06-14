package peote.text;

#if !macro
@:genericBuild(peote.text.Page.PageMacro.build("Page"))
class Page<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import peote.text.util.Macro;
import peote.text.util.GlyphStyleHasField;
import peote.text.util.GlyphStyleHasMeta;

class PageMacro
{
	static public function build(name:String):ComplexType return Macro.build(name, buildClass);
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>):ComplexType
	{
		className += Macro.classNameExtension(styleName, styleModule);
		
		if ( Macro.isNotGenerated(className) )
		{
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			var lineType = Line.LineMacro.buildClass("Line", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			
			var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
			var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
			
			var c = macro		

			// -------------------------------------------------------------------------------------------
			// -------------------------------------------------------------------------------------------

class $className
{
	public var x:Float = 0.0;
	public var y:Float = 0.0;
	public var xOffset:Float = 0.0;
	public var yOffset:Float = 0.0;
	public var maxX:Float = 0xffff;
	public var maxY:Float = 0xffff;
	
	@:allow(peote.text) public var fullWidth(default, null):Float = 0.0;
	@:allow(peote.text) public var fullHeight(default, null):Float = 0.0;
	
	//public var xDirection:Int = 1;  // <- TODO
	//public var yDirection:Int = 0;
	
	public var length(get, never):Int; // number of lines
	public inline function get_length():Int return lines.length;
	
	// TODO: optimize for neko/hl/cpp
	var lines = new Array<$lineType>();
	
	public inline function getLine(i:Int):$lineType return lines[i];
	@:allow(peote.text) inline function setLine(i:Int, line:$lineType) lines[i] = line;
	@:allow(peote.text) inline function pushLine(line:$lineType) lines.push(line);
	@:allow(peote.text) inline function resize(newLength:Int) {
		//TODO HAXE 4 lines.resize(newLength);
		lines.splice(newLength, lines.length - newLength);
	}
	
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