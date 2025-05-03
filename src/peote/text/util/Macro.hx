package peote.text.util;

#if macro
import haxe.Log;
import haxe.PosInfos;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;

class Macro
{
	// here is battle-test for the various ways:
	// https://github.com/HaxeFoundation/haxe/blob/62854a7c2947ca95fd7b85a80d7e056cbf1d4d41/tests/server/test/templates/csSafeTypeBuilding/Macro.macro.hx#L14
	// (thx to Rudy *hugs)
	
	/*
	public static var cache = new Map<String, Bool>();
	
	static public function isNotGenerated(className:String):Bool {
		if (cache.exists(className)) return false;
		else {
			cache[className] = true;
			return true;
		}
	}
	*/
	/*
	static public function typeNotGenerated(fullyQualifiedName:String):Bool {
		try {
			if(Context.getType(fullyQualifiedName) != null) return false;
		} catch(_) {}
		return true;
	}
	*/
	// ---------------------------------------------------------

	@:persistent static var generated = new Map<String, Bool>();

	static inline function isAlive(name:String):Bool {
		return try Context.getType(name) != null
			catch(s:String) {
				if (s != 'Type not found \'$name\'') throw(s);
				false;
			};
	}

	static public inline function typeAlreadyGenerated(fullyQualifiedName:String):Bool {
		if ( generated.exists(fullyQualifiedName) && isAlive(fullyQualifiedName) ) return true;
		generated.set(fullyQualifiedName, true);
		return false;
	}
	
	// --------------------------------------------------------

	static public function build(className:String,
		buildClass:String // className
		->Array<String>   // classPackage
		->Array<String>   // stylePack
		->String          // styleModule
		->String          // styleName
		->String          // styleSuperModule
		->String          // styleSuperName
		->ComplexType     // styleType
		->Array<String>   // styleField
		->ComplexType     // (return type)
	)
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
						
						// TODO: check if there is superclass!
						var styleField:Array<String>;
						//if (styleSuperName == null) styleField = styleModule.split(".").concat([styleName]);
						//else styleField = styleSuperModule.split(".").concat([styleSuperName]);
						styleField = style.module.split(".").concat([style.name]);
			
						return buildClass(
							className,
							Context.getLocalClass().get().pack,
							style.pack,
							style.module,
							style.name,
							styleSuperModule,
							styleSuperName,
							TypeTools.toComplexType(t),
							styleField
						);
					default: Context.error("Type for GlyphStyle expected", Context.currentPos());
				}
			default: Context.error("Type for GlyphStyle expected", Context.currentPos());
		}
		return null;
	}
	
	static public function debug(className:String, classPackage:Array<String>,
		stylePack:Array<String>, styleModule:String, styleName:String,
		styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>,
		?pos:PosInfos
	) 
	{
		#if peotetext_debug_macro
		Log.trace('generating Class: '+classPackage.concat([className]).join('.') , pos);			
/*		Log.trace("ClassName:"+className , pos);           // Glyph__peote_text_GlypStyle
		Log.trace("classPackage:" + classPackage , pos);   // [peote,text]	
		
		Log.trace("StylePackage:" + stylePack , pos);  // [peote.text]
		Log.trace("StyleModule:" + styleModule , pos); // peote.text.GlyphStyle
		Log.trace("StyleName:" + styleName , pos);     // GlyphStyle			
		Log.trace("StyleType:" + styleType , pos);     // TPath(...)
		Log.trace("StyleField:" + styleField , pos);   // [peote,text,GlyphStyle,GlyphStyle]
*/		
		#end
	}
	

	static public function classNameExtension(styleName:String, styleModule:String ):String {
		var styleModArray = styleModule.split(".");
		var styleMod = styleModArray.join("_");
		var extendClassNameBy = "__" + styleMod;
		if (styleModArray.pop() != styleName)
			extendClassNameBy += ((styleMod != "") ? "_" : "") + styleName;
			
		return extendClassNameBy;
	}
	
	static public function parseGlyphStyleFields(styleModule:String):GlyphStyleHasField {
			// parse GlyphStyle fields
			var glyphStyleHasField = new GlyphStyleHasField();
			
			var style_fields = switch Context.getType(styleModule) {
				case TInst(s,_): s.get();
				default: throw "error: can not parse glyphstyle";
			}
			for (field in style_fields.fields.get()) {//trace("param",Context.getTypedExpr(field.expr()).expr);
				var local = true;
				for (meta in field.meta.get()) {
					if (meta.name == "global") {
						local = false;
						break;
					}
				}
					
				switch (field.name) {
					case "color":   glyphStyleHasField.color   = true; if (local) glyphStyleHasField.local_color   = true;
					case "bgColor": glyphStyleHasField.bgColor = true; if (local) glyphStyleHasField.local_bgColor = true;
					case "width":   glyphStyleHasField.width   = true; if (local) glyphStyleHasField.local_width   = true;
					case "height":  glyphStyleHasField.height  = true; if (local) glyphStyleHasField.local_height  = true;
					case "rotation":glyphStyleHasField.rotation= true; if (local) glyphStyleHasField.local_rotation= true;
					case "weight":  glyphStyleHasField.weight  = true; if (local) glyphStyleHasField.local_weight  = true;
					case "tilt":    glyphStyleHasField.tilt    = true; if (local) glyphStyleHasField.local_tilt    = true;
					case "zIndex":  glyphStyleHasField.zIndex  = true; if (local) glyphStyleHasField.local_zIndex  = true;
					case "letterSpace":  glyphStyleHasField.letterSpace  = true; if (local) glyphStyleHasField.local_letterSpace  = true;
					default: // todo
				}
				// TODO: store other metas for custom anim and formula stuff
			}
			//trace("--- glyphStyleHasField",glyphStyleHasField);
			return glyphStyleHasField;
	}
	
	static public function parseGlyphStyleMetas(styleModule:String):GlyphStyleHasMeta {
			// parse GlyphStyle metas for font type
			var glyphStyleHasMeta = new GlyphStyleHasMeta();
			
			var style_fields = switch Context.getType(styleModule) {
				case TInst(s,_): s.get();
				default: throw "error: can not parse glyphstyle";
			}
			for (meta in style_fields.meta.get()) {
				switch (meta.name) {
					case "packed": glyphStyleHasMeta.packed = true;
					case "multiSlot":   glyphStyleHasMeta.multiSlot = true;
					case "multiTexture": glyphStyleHasMeta.multiTexture = true;
					//case "globalLineSpace": glyphStyleHasMeta.globalLineSpace = true; // <-- // TODO: maybe easier and only pageSetLineMetric()
					default:
				}
			}
			return glyphStyleHasMeta;
	}
	
}
#end
