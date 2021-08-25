package peote.text;

#if !macro
@:genericBuild(peote.text.Glyph.GlyphMacro.build("Glyph"))
class Glyph<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import peote.text.util.Macro;

class GlyphMacro
{
	static public function build(name:String):ComplexType return Macro.build(name, buildClass);
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>):ComplexType
	{
		className += Macro.classNameExtension(styleName, styleModule);
		
		if ( Macro.isNotGenerated(className) )
		{
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
						
			var glyphStyleHasMeta  = Macro.parseGlyphStyleMetas(styleModule+"."+styleName); //trace("Glyph - glyphStyleHasMeta:", glyphStyleHasMeta);
			var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName); //trace("Glyph - glyphStyleHasField:", glyphStyleHasField);

			var exprBlock = new Array<Expr>();
			if (glyphStyleHasField.local_width)  exprBlock.push( macro width = glyphStyle.width );
			if (glyphStyleHasField.local_height) exprBlock.push( macro height= glyphStyle.height );
			if (glyphStyleHasField.local_color)  exprBlock.push( macro color = glyphStyle.color );
			if (glyphStyleHasField.local_zIndex) exprBlock.push( macro zIndex= glyphStyle.zIndex );
			if (glyphStyleHasField.local_rotation) exprBlock.push( macro rotation = glyphStyle.rotation );
			if (glyphStyleHasField.local_weight) exprBlock.push( macro weight = glyphStyle.weight );
			if (glyphStyleHasField.local_tilt) exprBlock.push( macro tilt = glyphStyle.tilt );
			
			var c = macro

// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------

class $className implements peote.view.Element
{
	@:allow(peote.text) public var char(default, null):Int = -1;
	public function new() {}
	
	@:allow(peote.text) inline function setStyle(glyphStyle: $styleType) {
		$b{ exprBlock }
	}
	
}
			
// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------
						
			c.fields.push({
				name:  "x",
				meta: [{name:"posX", params:[], pos:Context.currentPos()}],
				access:  [Access.APublic],
				kind: FieldType.FVar(macro:Float, macro 0.0),
				pos: Context.currentPos(),
			});
			
			c.fields.push({
				name:  "y",
				meta: [{name:"posY", params:[], pos:Context.currentPos()}],
				access:  [Access.APublic],
				kind: FieldType.FVar(macro:Float, macro 0.0),
				pos: Context.currentPos(),
			});
			
			// TODO
			// to cut of a glyph horizontal - only for non-monospaced!
/*			c.fields.push({
				name:  "txOffset",
				meta: [{name:"texPosX", params:[], pos:Context.currentPos()}],
				access:  [Access.APublic],
				kind: FieldType.FVar(macro:Float, macro 0.0),
				pos: Context.currentPos(),
			});
			c.fields.push({
				name:  "tyOffset",
				meta: [{name:"texPosY", params:[], pos:Context.currentPos()}],
				access:  [Access.APublic],
				kind: FieldType.FVar(macro:Float, macro 0.0),
				pos: Context.currentPos(),
			});
*/			
			// --- add fields depending on unit/slots
			if (glyphStyleHasMeta.multiTexture) c.fields.push({
				name:  "unit",
				meta:  [{name:"texUnit", params:[], pos:Context.currentPos()},
						{name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
				access:  [Access.APrivate],
				kind: FieldType.FVar(macro:Int, macro 0),
				pos: Context.currentPos(),
			});
			if (glyphStyleHasMeta.multiSlot) c.fields.push({
				name:  "slot",
				meta:  [{name:"texSlot", params:[], pos:Context.currentPos()},
						{name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
				access:  [Access.APrivate],
				kind: FieldType.FVar(macro:Int, macro 0),
				pos: Context.currentPos(),
			});
			
			// --- add fields depending on style
			if (glyphStyleHasField.local_color) c.fields.push({
				name:  "color",
				meta:  [{name:"color", params:[], pos:Context.currentPos()}],
				access:  [Access.APublic],
				kind: FieldType.FVar(macro:peote.view.Color, macro 0xffffffff),
				pos: Context.currentPos(),
			});
			
			if (glyphStyleHasField.zIndex) {
				var meta = [{name:"zIndex", params:[], pos:Context.currentPos()}];
				if (!glyphStyleHasField.local_zIndex) meta.push({name:"@const", params:[], pos:Context.currentPos()});
				c.fields.push({
					name:  "zIndex",
					meta:  meta,
					access:  [Access.APublic],
					kind: FieldType.FVar(macro:Int, macro 0), // default value is set via Fontprogram!
					pos: Context.currentPos(),
				});
			}
			
			if (glyphStyleHasField.rotation) {
				var meta = [{name:"rotation", params:[], pos:Context.currentPos()}];
				if (!glyphStyleHasField.local_rotation) meta.push({name:"@const", params:[], pos:Context.currentPos()});
				c.fields.push({
					name:  "rotation",
					meta:  meta,
					access:  [Access.APublic],
					kind: FieldType.FVar(macro:Float, macro 0.0), // default value is set via Fontprogram!
					pos: Context.currentPos(),
				});
			}
			
			if (glyphStyleHasField.local_tilt) c.fields.push({
				name:  "tilt",
				meta:  [{name:"custom", params:[], pos:Context.currentPos()}],
				access:  [Access.APublic],
				kind: FieldType.FVar(macro:Float, macro 0.0),
				pos: Context.currentPos(),
			});
			
			if (glyphStyleHasField.local_weight) c.fields.push({
				name:  "weight",
				meta:  [{name:"custom", params:[], pos:Context.currentPos()},
				       {name:"varying", params:[], pos:Context.currentPos()}],
				access:  [Access.APublic],
				kind: FieldType.FVar(macro:Float, macro 0.0),
				pos: Context.currentPos(),
			});
			
			// ------------- add fields depending on font-type and style ------------------
			
			if (glyphStyleHasMeta.packed)
			{			
				if (glyphStyleHasField.local_width) {
					c.fields.push({
						name:  "width",
						access:  [Access.APublic],
						kind: FieldType.FProp("default", "set", macro:Float),
						pos: Context.currentPos(),
					});
					c.fields.push({
						name: "set_width",
						access: [Access.APrivate],
						pos: Context.currentPos(),
						kind: FFun({
							args: [{name:"value", type:macro:Float}],
							expr: macro {
								if (width > 0.0) w = w / width * value else w = 0;
								return width = value;
							},
							ret: macro:Float
						})
					});
				}
								
				if (glyphStyleHasField.local_height) {
					c.fields.push({
						name:  "height",
						access:  [Access.APublic],
						kind: FieldType.FProp("default", "set", macro:Float),
						pos: Context.currentPos(),
					});
					c.fields.push({
						name: "set_height",
						access: [Access.APrivate],
						pos: Context.currentPos(),
						kind: FFun({
							args: [{name:"value", type:macro:Float}],
							expr: macro {
								if (height > 0.0) h = h / height * value else h = 0;
								return height = value;
							},
							ret: macro:Float
						})
					});
				}
				
				c.fields.push({
					name: "w",
					meta: [{name:"sizeX", params:[], pos:Context.currentPos()},
					       //{name:"varying", params:[], pos:Context.currentPos()},
					       {name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access: [Access.APrivate],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
				c.fields.push({
					name: "h",
					meta: [{name:"sizeY", params:[], pos:Context.currentPos()},
					       {name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access: [Access.APrivate],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
				c.fields.push({
					name: "tx",
					meta: [{name:"texX", params:[], pos:Context.currentPos()},
					       {name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access: [Access.APrivate],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
				c.fields.push({
					name:  "ty",
					meta: [{name:"texY", params:[], pos:Context.currentPos()},
					       {name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access: [Access.APrivate],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
				c.fields.push({
					name:  "tw",
					meta: [{name:"texW", params:[], pos:Context.currentPos()},
					       {name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access: [Access.APrivate],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
				c.fields.push({
					name: "th",
					meta: [{name:"texH", params:[], pos:Context.currentPos()},
					       {name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access: [Access.APrivate],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});

			}
			else
			{
				var meta = [{name:"sizeX", params:[], pos:Context.currentPos()},
							{name:"varying", params:[], pos:Context.currentPos()}]; // TODO: for outlnine and weight
				if (!glyphStyleHasField.local_width) meta.push({name:"@const", params:[], pos:Context.currentPos()});
				c.fields.push({
					name:  "width",
					meta: meta,
					access:  [Access.APublic],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
				
				meta = [{name:"sizeY", params:[], pos:Context.currentPos()}];
				if (!glyphStyleHasField.local_height) meta.push({name:"@const", params:[], pos:Context.currentPos()});
				c.fields.push({
					name:  "height",
					meta: meta,
					access:  [Access.APublic],
					kind: FieldType.FVar(macro:Float, macro 0.0),
					pos: Context.currentPos(),
				});
				
				c.fields.push({
					name:  "tile",
					meta: [{name:"texTile", params:[], pos:Context.currentPos()},
					       {name:":allow", params:[macro peote.text], pos:Context.currentPos()}],
					access:  [Access.APrivate],
					kind: FieldType.FVar(macro:Int, macro 0),
					pos: Context.currentPos(),
				});
				
			}
			Context.defineModule(classPackage.concat([className]).join('.'),[c]);
			//trace(new haxe.macro.Printer().printTypeDefinition(c));
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
}
#end
