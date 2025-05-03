package peote.text;

#if !macro
@:genericBuild(peote.text.PageLine.PageLineMacro.build("PageLine"))
class PageLine<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import peote.text.util.Macro;

class PageLineMacro
{
	static public function build(name:String):ComplexType return Macro.build(name, buildClass);
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>):ComplexType
	{
		className += Macro.classNameExtension(styleName, styleModule);
		var fullyQualifiedName:String = classPackage.concat([className]).join('.');
		
		if ( !Macro.typeAlreadyGenerated(fullyQualifiedName) )
		{
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			var glyphType = Glyph.GlyphMacro.buildClass("Glyph", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			Context.defineModule(fullyQualifiedName, [ getTypeDefinition(className, styleModule, styleName, glyphType) ]);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
	
	static public function getTypeDefinition(className:String, styleModule:String, styleName:String, glyphType:ComplexType):TypeDefinition
	{	
		var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName);
		var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName);
		
		// -------------------------------------------------------------------------------------------
		
		var c = macro class $className
		{
			public var y(default, null):Float = 0.0;
			
			public var textSize(default, null):Float = 0.0; // size of all letters into line (in pixel)
			
			// line metric
			public var lineHeight(default, null):Float = 0.0; // full line-height
			public var base(default, null):Float = 0.0; // fontrange-baseline
			public var height(default, null):Float = 0.0; // height of greatest letter into fontrange
						
			public var length(get, never):Int; // number of glyphes
			public inline function get_length():Int return glyphes.length;
						
			// TODO: optimize for neko/hl/cpp
			var glyphes = new Array<$glyphType>();
			
			public inline function getGlyph(i:Int):$glyphType return glyphes[i];
			inline function setGlyph(i:Int, glyph:$glyphType) glyphes[i] = glyph;
			inline function pushGlyph(glyph:$glyphType) glyphes.push(glyph);
			inline function insertGlyph(pos:Int, glyph:$glyphType) glyphes.insert(pos, glyph);
			
			inline function splice(pos:Int, len:Int):Array<$glyphType> return glyphes.splice(pos, len);
			inline function resize(newLength:Int) {
				//TODO HAXE 4 lines.resize(newLength);
				glyphes.splice(newLength, glyphes.length - newLength);
			}
			inline function append(a:Array<$glyphType>) {
				glyphes = glyphes.concat(a);
			}
						
			public var visibleFrom(default, null):Int = 0;
			public var visibleTo(default, null):Int = 0;
			
			public var updateFrom(default, null):Int = 0x1000000;
			public var updateTo(default, null):Int = 0;
			
			function new() {}
		}
		
		// -------------------------------------------------------------------------------------------
		
		c.meta = [ {name:":allow", params:[macro peote.text], pos:Context.currentPos()} ];
			
		// ------------- add fields depending on font-type and style ------------------
		/*			
		if (glyphStyleHasMeta.globalLineSpace) // <-- // TODO: maybe easier and only pageSetLineMetric()
		{
			// TODO: add only if NOT @globalLineSpace at glyphstyle
			// var lineSpace:Float = 0.0
		}
		*/			
		// TODO: wordwrapping
		// var wordwrapAt:Array<Int> = null;

		return c;
	}
}
#end
