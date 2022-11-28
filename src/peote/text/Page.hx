package peote.text;

#if !macro
@:genericBuild(peote.text.Page.PageMacro.build("Page"))
class Page<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import peote.text.util.Macro;

class PageMacro
{
	static public function build(name:String):ComplexType return Macro.build(name, buildClass);
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>):ComplexType
	{
		className += Macro.classNameExtension(styleName, styleModule);
		
		if ( Macro.isNotGenerated(className) )
		{
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			//var lineType = Line.LineMacro.buildClass("Line", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			var pageLineType = PageLine.PageLineMacro.buildClass("PageLine", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			
			var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
			var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
			
			var c = macro		

			// -------------------------------------------------------------------------------------------
			// -------------------------------------------------------------------------------------------

class $className
{
	@:allow(peote.text) public var x(default, null):Float = 0.0;
	@:allow(peote.text) public var y(default, null):Float = 0.0;
	@:allow(peote.text) public var xOffset(default, null):Float = 0.0;
	@:allow(peote.text) public var yOffset(default, null):Float = 0.0;
	@:allow(peote.text) public var width(default, null):Float = 0xffff; // visible width of the page (in pixel)
	@:allow(peote.text) public var height(default, null):Float = 0xffff; // visible height of the page (in pixel)
	
	@:allow(peote.text) public var textWidth(default, null):Float = 0.0; // pixel size of longest line
	@:allow(peote.text) public var longestLines(default, null):Int = 0;  // how many longest lines
	@:allow(peote.text) public var textHeight(default, null):Float = 0.0; // pixel size of all lines
	
	
	// TODO: optimize for neko/hl/cpp ... alternatively also per vector and ringbuffer
	@:allow(peote.text) var pageLines = new Array<$pageLineType>();
	
	public var length(get, never):Int; // number of lines
	public inline function get_length():Int return pageLines.length;
	
	public inline function getPageLine(i:Int):$pageLineType return pageLines[i];
	@:allow(peote.text) inline function setLine(i:Int, line:$pageLineType) pageLines[i] = line;
	@:allow(peote.text) inline function pushLine(line:$pageLineType) pageLines.push(line);

	@:allow(peote.text) inline function resize(newLength:Int) {
		//TODO HAXE 4 lines.resize(newLength);
		pageLines.splice(newLength, pageLines.length - newLength);
	}
		
	@:allow(peote.text) inline function spliceLines(pos:Int, len:Int):Array<$pageLineType> {
		//TODO: optimize
		return pageLines.splice(pos, len);
	}
	
	@:allow(peote.text) inline function append(a:Array<$pageLineType>) {
		pageLines = pageLines.concat(a);
	}
	
	
	
	@:allow(peote.text) public var visibleLineFrom(default, null):Int = 0;
	@:allow(peote.text) public var visibleLineTo(default, null):Int = 0;
	
	@:allow(peote.text) public var updateLineFrom(default, null):Int = 0x1000000;
	@:allow(peote.text) public var updateLineTo(default, null):Int = 0;

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