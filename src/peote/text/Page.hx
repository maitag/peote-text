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
		var fullyQualifiedName:String = classPackage.concat([className]).join('.');

		if ( !Macro.typeAlreadyGenerated(fullyQualifiedName) )
		{
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			var pageLineType = PageLine.PageLineMacro.buildClass("PageLine", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
	
			Context.defineModule(fullyQualifiedName, [ getTypeDefinition(className, styleModule, styleName, pageLineType) ]);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}

	static public function getTypeDefinition(className:String, styleModule:String, styleName:String, pageLineType:ComplexType):TypeDefinition
	{	
		var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
		var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
		
		// -------------------------------------------------------------------------------------------

		var c = macro class $className
		{
			public var x(default, null):Float = 0.0;
			public var y(default, null):Float = 0.0;
			public var xOffset(default, null):Float = 0.0;
			public var yOffset(default, null):Float = 0.0;
			public var width(default, null):Float = 0xffff; // visible width of the page (in pixel)
			public var height(default, null):Float = 0xffff; // visible height of the page (in pixel)
			
			public var textWidth(default, null):Float = 0.0; // pixel size of longest line
			public var textHeight(default, null):Float = 0.0; // pixel size of all lines
			
			
			// TODO: optimize for neko/hl/cpp ... alternatively also per vector and ringbuffer
			var pageLines = new Array<$pageLineType>();
			
			public var length(get, never):Int; // number of lines
			public inline function get_length():Int return pageLines.length;
			
			public inline function getPageLine(i:Int):$pageLineType return pageLines[i];
			inline function setLine(i:Int, line:$pageLineType) pageLines[i] = line;
			inline function pushLine(line:$pageLineType) pageLines.push(line);

			inline function resize(newLength:Int) {
				//TODO HAXE 4 lines.resize(newLength);
				pageLines.splice(newLength, pageLines.length - newLength);
			}
				
			inline function spliceLines(pos:Int, len:Int):Array<$pageLineType> {
				//TODO: optimize
				return pageLines.splice(pos, len);
			}
			
			inline function append(a:Array<$pageLineType>) {
				pageLines = pageLines.concat(a);
			}
			
			
			public var visibleLineFrom(default, null):Int = 0;
			public var visibleLineTo(default, null):Int = 0;
			
			public var updateLineFrom(default, null):Int = 0x1000000;
			public var updateLineTo(default, null):Int = 0;

			public function new() {}
		}
		
		// -------------------------------------------------------------------------------------------

		c.meta = [ {name:":allow", params:[macro peote.text], pos:Context.currentPos()} ];
		
		// ------------- add fields depending on font-type and style ------------------
		/*
			if (glyphStyleHasMeta.globalLineSpace) // <-- // TODO: maybe easier and only pageSetLineMetric()
			{
				// TODO: add only if @globalLineSpace at glyphstyle	
				c.fields.push({
					name: "lineSpace",
					meta: [{name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access: [Access.APublic],
					kind: FieldType.FProp("default", "null", macro:Float, macro 0.0),
					//kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
			}
		*/			
		
		return c;
	}
}
#end