package peote.text;

#if !macro
@:genericBuild(peote.text.Page.PageMacro.build())
class Page<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;

class PageMacro
{
	public static var cache = new Map<String, Bool>();
	
	static public function build()
	{	
		switch (Context.getLocalType()) {
			case TInst(_, [t]):
				switch (t) {
					case TInst(n, []):
						var style = n.get();
						var styleSuperName:String = null;
						var styleSuperModule:String = null;
						var s = style;
						while (s.superClass != null) {
							s = s.superClass.t.get(); trace("->" + s.name);
							styleSuperName = s.name;
							styleSuperModule = s.module;
						}
						return buildClass(
							"Page", Context.getLocalClass().get().pack, style.pack, style.module, style.name, styleSuperModule, styleSuperName, TypeTools.toComplexType(t)
						);	
					default: Context.error("Type for GlyphStyle expected", Context.currentPos());
				}
			default: Context.error("Type for GlyphStyle expected", Context.currentPos());
		}
		return null;
	}
		
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType):ComplexType
	{		
		var styleMod = styleModule.split(".").join("_");
		
		className += "__" + styleMod;
		if (styleModule.split(".").pop() != styleName) className += ((styleMod != "") ? "_" : "") + styleName;
		
		if (!cache.exists(className))
		{
			cache[className] = true;
			
			var styleField:Array<String>;
			//if (styleSuperName == null) styleField = styleModule.split(".").concat([styleName]);
			//else styleField = styleSuperModule.split(".").concat([styleSuperName]);
			styleField = styleModule.split(".").concat([styleName]);
			
			var lineType = Line.LineMacro.buildClass("Line", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType);
			
			#if peotetext_debug_macro
			trace('generating Class: '+classPackage.concat([className]).join('.'));	
			
			trace("ClassName:"+className);           // FontProgram__peote_text_GlypStyle
			trace("classPackage:" + classPackage);   // [peote,text]	
			
			trace("StylePackage:" + stylePack);  // [peote.text]
			trace("StyleModule:" + styleModule); // peote.text.GlyphStyle
			trace("StyleName:" + styleName);     // GlyphStyle			
			trace("StyleType:" + styleType);     // TPath(...)
			trace("StyleField:" + styleField);   // [peote,text,GlyphStyle,GlyphStyle]
			#end
			
			var glyphStyleHasMeta = Glyph.GlyphMacro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
			var glyphStyleHasField = Glyph.GlyphMacro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
			
			// -------------------------------------------------------------------------------------------
			var c = macro		

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