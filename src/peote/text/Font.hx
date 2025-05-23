package peote.text;

#if !macro
@:genericBuild(peote.text.Font.FontMacro.build("Font"))
class Font<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import peote.text.util.Macro;

class FontMacro
{
	static public function build(name:String):ComplexType return Macro.build(name, buildClass);
	static public function buildClass(className:String, classPackage:Array<String>, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType, styleField:Array<String>):ComplexType
	{
		className += Macro.classNameExtension(styleName, styleModule);
		var fullyQualifiedName:String = classPackage.concat([className]).join('.');

		if ( !Macro.typeAlreadyGenerated(fullyQualifiedName) )
		{	
			Macro.debug(className, classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);

			var fontProgramType = //FontProgram.FontProgramMacro.buildClass("FontProgram", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
				// TPath({ pack:classPackage, name:"FontProgram" + Macro.classNameExtension(styleName, styleModule), params:[] });
				TPath({ pack:classPackage, name:"FontProgram", params:[TPType(styleType)] });

			var glyphType  = Glyph.GlyphMacro.buildClass("Glyph", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			var lineType  = Line.LineMacro.buildClass("Line", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			//var pageLineType = 
			// PageLine.PageLineMacro.buildClass("PageLine", classPackage, stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
			
			var fontType:ComplexType =  TPath({ pack:classPackage, name:"Font" + Macro.classNameExtension(styleName, styleModule), params:[] });

			var fontProgramPath:TypePath =  { pack:classPackage, name:"FontProgram" + Macro.classNameExtension(styleName, styleModule), params:[] };
			var glyphPath:TypePath = { pack:classPackage, name:"Glyph" + Macro.classNameExtension(styleName, styleModule), params:[] };
			var linePath:TypePath =  { pack:classPackage, name:"Line" + Macro.classNameExtension(styleName, styleModule), params:[] };
			
			#if peote_ui
			var uiTextLineType:ComplexType = // peote.ui.interactive.UITextLine.UITextLineMacro.buildClass("UITextLine", ["peote","ui","interactive"], stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
				TPath({ pack:["peote","ui","interactive"], name:"UITextLine", params:[TPType(styleType)] });
			var uiTextLinePath:TypePath =  { pack:["peote","ui","interactive"], name:"UITextLine" + Macro.classNameExtension(styleName, styleModule), params:[] };
			
			var uiTextPageType:ComplexType = //peote.ui.interactive.UITextPage.UITextPageMacro.buildClass("UITextPage", ["peote","ui","interactive"], stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType, styleField);
				// TPath({ pack:["peote","ui","interactive"], name:"UITextPage" + Macro.classNameExtension(styleName, styleModule), params:[] });
				TPath({ pack:["peote","ui","interactive"], name:"UITextPage", params:[TPType(styleType)] });
			var uiTextPagePath:TypePath =  { pack:["peote","ui","interactive"], name:"UITextPage" + Macro.classNameExtension(styleName, styleModule), params:[] };
			#end
			
			var styleModulName = styleModule.split(".").pop();
			var stylePath:TypePath = ( styleModulName == styleName) ? { pack:stylePack, name:styleName, params:[] } 
				:{ pack:stylePack, name:styleModulName, params:[], sub:styleName } ;
			
			Context.defineModule(fullyQualifiedName, [ getTypeDefinition(className, stylePath, stylePack, styleModule, styleName, styleType, glyphType, lineType, fontType, fontProgramType, fontProgramPath, glyphPath, linePath
				#if peote_ui ,uiTextLineType, uiTextLinePath, uiTextPageType, uiTextPagePath #end
			)]);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
		
	static public function getTypeDefinition(className:String, stylePath:TypePath, stylePack:Array<String>, styleModule:String, styleName:String, styleType:ComplexType,
		glyphType:ComplexType, lineType:ComplexType, fontType:ComplexType, fontProgramType:ComplexType, fontProgramPath:TypePath, glyphPath:TypePath, linePath:TypePath
		#if peote_ui ,uiTextLineType:ComplexType, uiTextLinePath:TypePath, uiTextPageType:ComplexType, uiTextPagePath:TypePath #end
		):TypeDefinition
	{		
		var glyphStyleHasMeta = Macro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
		var glyphStyleHasField = Macro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
		
		var rangeMappingType:ComplexType;
		var rangeType:ComplexType;
		var textureType:ComplexType;
		
		if (glyphStyleHasMeta.multiTexture) {
			textureType = macro: peote.view.TextureCache;
			if (glyphStyleHasMeta.multiSlot) {
				if (glyphStyleHasMeta.packed) {
					rangeType = macro: {unit:Int, slot:Int, fontData:peote.text.Gl3FontData};
				}
				else {
					rangeType = macro: {unit:Int, slot:Int, min:Int, max:Int, height:Float, base:Float};
				}
			}
			else {
				if (glyphStyleHasMeta.packed) {
					rangeType = macro: {unit:Int, fontData:peote.text.Gl3FontData};
				}
				else {
					rangeType = macro: {unit:Int, min:Int, max:Int, height:Float, base:Float};
				}
			}
			rangeMappingType = macro: haxe.ds.Vector<$rangeType>;
		}
		else {
			textureType = macro: peote.view.Texture;
			if (glyphStyleHasMeta.multiSlot) {
				if (glyphStyleHasMeta.packed) {
					rangeType = macro: {slot:Int, fontData:peote.text.Gl3FontData};
				}
				else {
					rangeType = macro: {slot:Int, min:Int, max:Int, height:Float, base:Float};
				}
				rangeMappingType = macro: haxe.ds.Vector<$rangeType>;
			}
			else {
				if (glyphStyleHasMeta.packed) {
					rangeType = rangeMappingType = macro: peote.text.Gl3FontData;
				}
				else {
					rangeType = rangeMappingType = macro: {min:Int, max:Int, height:Float, base:Float};
				}
			}
		}
		
		var c = macro

// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------
			
class $className
{
	var path:String;
	var jsonFilename:String;

	public var config:peote.text.FontConfig;
	
	var rangeMapping:$rangeMappingType;				
	public var textureCache:$textureType;

	var maxTextureSize:Int;
	
	// from json
	var ranges:Array<peote.text.Range>;
	var rangeSize = 0x1000;      // amount of unicode range-splitting
	
	public var kerning = false;
					
	var rParsePathConfig = new EReg("^(.*?)([^/]+)$", "");
	var rParseEnding = new EReg("\\.[a-z]+$", "i");
	var rComments = new EReg("//.*?$", "gm");
	// TODO: check https://try.haxe.org/#d86D1Fee
	//var rComments:EReg = ~/(\/\/[^"\n\r]*(?:"[^"\n\r]*"[^"\n\r]*)*[\r\n]|\/\*([^*]|\*(?!\/))*?\*\/)(?=[^"]*(?:"[^"]*"[^"]*)*$)/gs;
	//var rComments:EReg = ~/(\/\/[^"\r\n]*(?:"[^"\r\n]*"[^"\r\n]*)*|\/\*([^*]|\*(?!\/))*?\*\/)(?=[^"]*(?:"[^"]*"[^"]*)*$)/gs;
	var rHexToDec = new EReg("(\"\\s*)?(0x[0-9a-f]+)(\\s*\")?", "gi");
	
	public function new(configJsonPath:String, ranges:Array<peote.text.Range>=null, kerning:Bool=true, maxTextureSize:Int=16384) 
	{
		if (rParsePathConfig.match(configJsonPath)) {
			path = rParsePathConfig.matched(1);
			jsonFilename = rParsePathConfig.matched(2);
		} else throw("Can't load font, error in path to jsonfile: "+'"'+configJsonPath+'"');
		
		this.ranges = ranges;
		this.kerning = kerning;
		this.maxTextureSize = maxTextureSize;
	}
	
	@:keep public function createFontProgram(fontStyle:$styleType, isMasked:Bool = false, bufferMinSize:Int = 1024, bufferGrowSize:Int = 1024, bufferAutoShrink:Bool = true):$fontProgramType
	// @:keep public function createFontProgram(fontStyle:$styleType, isMasked:Bool = false, bufferMinSize:Int = 1024, bufferGrowSize:Int = 1024, bufferAutoShrink:Bool = true):peote.text.FontProgram<$styleType>
	{
		//return new peote.text.FontProgram<$styleType>(this, fontStyle, isMasked, bufferMinSize, bufferGrowSize, bufferAutoShrink);
		return new $fontProgramPath(this, fontStyle, isMasked, bufferMinSize, bufferGrowSize, bufferAutoShrink);
	}
	
	@:keep public function createFontStyle():$styleType return new $stylePath();		
	public function createGlyph():$glyphType return new $glyphPath();
	public function createLine():$lineType return new $linePath();
	
	// -------- peote-ui ---------
	
	#if peote_ui
	@:keep public function createUITextLine(xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0, text:String,
	                ?fontStyle:$styleType, ?config:peote.ui.config.TextConfig):$uiTextLineType
	{
		return new $uiTextLinePath(xPosition, yPosition, width, height, zIndex, text, this, fontStyle, config);
	}
	@:keep public function createUITextPage(xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0, text:String,
	                ?fontStyle:$styleType, ?config:peote.ui.config.TextConfig):$uiTextPageType
	{
		return new $uiTextPagePath(xPosition, yPosition, width, height, zIndex, text, this, fontStyle, config);
	}
	#end
	
	// ---------------------------
	
	public inline function getRange(charcode:Int):$rangeType
	{
		${switch (glyphStyleHasMeta.packed) {
			case true:
				switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
					case true: macro return rangeMapping.get(Std.int(charcode/rangeSize));
					default: macro return rangeMapping;
				}
			default:
				switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
					case true: macro {
						var range = rangeMapping.get(Std.int(charcode / rangeSize));
						if (range != null) {
							if (charcode >= range.min && charcode <= range.max) return range;
							else return null;
						} else return null;
					}
					default: macro {
						if (charcode >= rangeMapping.min && charcode <= rangeMapping.max) return rangeMapping;
						else return null;
					}
				}						
		}}
	}

	// --------------------------- Loading -------------------------
	public function load(onLoad:$fontType->Void, ?onProgressOverall:Int->Int->Void, debug:Bool=false)
	// public function load(onLoad:peote.text.Font<$styleType>->Void, ?onProgressOverall:Int->Int->Void, debug:Bool=false)
	{
		utils.Loader.text(path + jsonFilename, debug, function(jsonString:String)
		{	
			jsonString = rComments.replace(jsonString, "");
			jsonString = rHexToDec.map(jsonString, function(r) return Std.string(Std.parseInt(r.matched(2))));
			
			var parser = new json2object.JsonParser<peote.text.FontConfig>();
			config = parser.fromJson(jsonString, path + jsonFilename);
			
			for (e in parser.errors) {
				var pos = switch (e) {case IncorrectType(_, _, pos) | IncorrectEnumValue(_, _, pos) | InvalidEnumConstructor(_, _, pos) | UninitializedVariable(_, pos) | UnknownVariable(_, pos) | ParserError(_, pos) | CustomFunctionException(_, pos): pos;}
				trace(pos.lines[0].number);
				if (pos != null) haxe.Log.trace(json2object.ErrorUtils.convertError(e), {fileName:pos.file, lineNumber:pos.lines[0].number,className:"",methodName:""});
			}
			
			
			// TODO: shift all from single range into ranges to write also without ranges-array
			
			rangeSize = config.rangeSplitSize; // TODO: check!
			
			if (config.line != null) {
				// if (config.line.height == null) config.line.height = //TODO: set to same as tile-height
			}

			${switch (glyphStyleHasMeta.packed) {
				case true: macro {
					if (!config.packed) {
						var error = 'Error, for '+$v{styleName}+' "@packed" in "' + path + jsonFilename +'" set "packed":true';
						haxe.Log.trace(error, {fileName:path+jsonFilename, lineNumber:0,className:"",methodName:""});
						throw(error);
					}
				}
				default: macro {
					if (config.packed) {
						var error = 'Error, metadata of '+$v{styleName}+' class has to be "@packed" for "' + path + jsonFilename + '" and "packed":true';
						haxe.Log.trace(error, {fileName:path+jsonFilename, lineNumber:0,className:"",methodName:""});
						throw(error);
					}
				}
			}}
			
			if (kerning && config.kerning != null) kerning = config.kerning;
			
			${switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
				case true: macro {}
				default: macro {
					if (ranges == null && config.ranges.length > 1) {
						var error = 'Error, set '+$v{styleName}+' to @multiSlot and/or @multiTexture or define a single range while Font creation or inside "' + path + jsonFilename +'"';
						haxe.Log.trace(error, {fileName:path+jsonFilename, lineNumber:0,className:"",methodName:""});
						throw(error);
					}
				}
			}}

			var found_ranges = new Array<{image:String,data:String,slot:{width:Int, height:Int},tiles:{x:Int, y:Int},line:{height:Float, base:Float},range:peote.text.Range}>();
			
			for( item in config.ranges )
			{
				var min = item.range.min;
				var max = item.range.max;
				
				if (ranges != null) {
					for (r in ranges) {
						if ((r.min >= min && r.min <= max) || (r.max >= min && r.max <= max)) {
							found_ranges.push(item);
							break;
						}
					}
				}
				else found_ranges.push(item);
				
				${switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
					case true: macro {}
					default: macro if (found_ranges.length == 1) break;
				}}
			}
			if (found_ranges.length == 0) {
				var error = 'Error, can not found any ranges inside font-config "'+path+jsonFilename+'" that fit '+ranges;
				haxe.Log.trace(error, {fileName:path+jsonFilename, lineNumber:0,className:"",methodName:""});
				throw(error);
			}
			else config.ranges = found_ranges;

			init(onLoad, onProgressOverall, debug);
		});	
	}
	
	private function init(onLoad:$fontType->Void, onProgressOverall:Int->Int->Void, debug:Bool)
	// private function init(onLoad:peote.text.Font<$styleType>->Void, onProgressOverall:Int->Int->Void, debug:Bool)
	{
		${switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
			case true: macro
				rangeMapping = new haxe.ds.Vector<$rangeType>(Std.int(0x1000 * 20 / rangeSize));// TODO: is ( 0x1000 * 20) the greatest charcode for unicode ?
			default: macro {}
		}}
		
		${switch (glyphStyleHasMeta.multiTexture) {
			case true: macro {
				var sizes = new Array<{width:Int, height:Int, slots:Int, config:peote.view.TextureConfig}>();
				for (item in config.ranges) {
					var found = false;
					${switch (glyphStyleHasMeta.multiSlot) {
						case true: macro {
							for (i in 0...sizes.length) {
								if (sizes[i].width == item.slot.width && sizes[i].height == item.slot.height) {
									sizes[i].slots++;
									found = true;
								}
							}
						}
						default: macro {}
					}}
					if (!found) sizes.push({width:item.slot.width, height:item.slot.height, slots:1, config:{format:peote.view.TextureFormat.RGBA, smoothExpand:true, smoothShrink:true}});
				}
				textureCache = new peote.view.TextureCache(sizes);
			}
			default: macro {
				var w:Int = 0;
				var h:Int = 0;
				for (item in config.ranges) {
					if (item.slot.width > w) w = item.slot.width;
					if (item.slot.height > h) h = item.slot.height;
				}
				textureCache = new peote.view.Texture(w, h, config.ranges.length,
					{format:peote.view.TextureFormat.RGBA, maxTextureSize:maxTextureSize, smoothShrink: true, smoothExpand: true}
				);
			}
		}}
	
		${switch (glyphStyleHasMeta.packed)	{
			case true: macro loadFontData(onLoad, onProgressOverall, debug);
			default: macro loadImages(onLoad, onProgressOverall, debug);
		}}
	}
	
	private function loadFontData(onLoad:$fontType->Void, onProgressOverall:Int->Int->Void, debug:Bool):Void
	// private function loadFontData(onLoad:peote.text.Font<$styleType>->Void, onProgressOverall:Int->Int->Void, debug:Bool):Void
	{		
		var gl3FontData = new Array<peote.text.Gl3FontData>();		
		utils.Loader.bytesArray(
			config.ranges.map(function (v) {
				if (v.data != null) return path + v.data;
				else return path + rParseEnding.replace(v.image, ".dat");
			}),
			debug,
			function(index:Int, bytes:lime.utils.Bytes) { // after .dat is loaded
				gl3FontData[index] = new peote.text.Gl3FontData(bytes, config.ranges[index].range.min, config.ranges[index].range.max, kerning);
			},
			function(bytes:Array<lime.utils.Bytes>) { // after all .dat is loaded
				loadImages(gl3FontData, onLoad, onProgressOverall, debug);
			}
		);
	}
	
	public function embed()
	{
		// TODO
	}
	
	@:access(peote.text.Range)
	private function loadImages(?gl3FontData:Array<peote.text.Gl3FontData>, onLoad:$fontType->Void, onProgressOverall:Int->Int->Void, debug:Bool):Void
	// private function loadImages(?gl3FontData:Array<peote.text.Gl3FontData>, onLoad:peote.text.Font<$styleType>->Void, onProgressOverall:Int->Int->Void, debug:Bool):Void
	{		
		//trace("load images");
		utils.Loader.imageArray(
			config.ranges.map(function (v) return path + v.image),
			debug,
			function(index:Int, loaded:Int, size:Int) {
				//trace(' loading G3Font-Images progress ' + Std.int(loaded / size * 100) + "%" , " ("+loaded+" / "+size+")");
				if (onProgressOverall != null) onProgressOverall(loaded, size);
			},
			function(index:Int, image:lime.graphics.Image) { // after every image is loaded
				//trace('File number $index loaded completely.');
				
				${switch (glyphStyleHasMeta.packed)
				{
					case true: macro // ------- Gl3Font -------
					{
						// recalc texture-coords
						var gl3font = gl3FontData[index];
						for (charcode in gl3font.rangeMin...gl3font.rangeMax+1) {
							var m = gl3font.getMetric(charcode);
							if (m != null) {
								m.u *= image.width;
								m.v *= image.height;
								m.w *= image.width;
								m.h *= image.height;
								gl3font.setMetric(charcode, m);
							}
						}
						
						// sort ranges into rangeMapping
						var range = config.ranges[index].range;

						${switch (glyphStyleHasMeta.multiTexture) {
							case true: macro {
								var p = textureCache.addData(image); 
								//trace( image.width+"x"+image.height, "texture-unit:" + p.unit, "texture-slot:" + p.slot);							
								for (i in Std.int(range.min / rangeSize)...Std.int(range.max / rangeSize) + 1) {
									${switch (glyphStyleHasMeta.multiSlot) {
										case true: macro rangeMapping.set(i, {unit:p.unit, slot:p.slot, fontData:gl3font});
										default: macro rangeMapping.set(i, {unit:p.unit, fontData:gl3font});
									}}
								}
							}
							default: switch (glyphStyleHasMeta.multiSlot) {
								case true: macro {
									textureCache.setData(image, index);
									for (i in Std.int(range.min / rangeSize)...Std.int(range.max / rangeSize)+1) {
										rangeMapping.set(i, {slot:index, fontData:gl3font});
									}
								}
								default: macro {
									textureCache.setData(image);
									rangeMapping = gl3font;
								}
							}
						}}

						// because first charcode is need to get the default metrics sometimes (e.g. for new pagelines)
						range.min = gl3font.firstCharCode;
						
					}
					default: macro // ------- simple font -------
					{
						var tilesX:Null<Int> = null;
						var tilesY:Null<Int> = null;
						if ( config.ranges[index].tiles != null) {
							tilesX = config.ranges[index].tiles.x;
							tilesY = config.ranges[index].tiles.y;
						}
						else if (config.tiles != null) {
							tilesX = config.tiles.x;
							tilesY = config.tiles.y;
						}
						else {
							var error = 'Error, can not found tiles inside font-config "'+path+jsonFilename+'"';
							haxe.Log.trace(error, {fileName:path+jsonFilename, lineNumber:0,className:"",methodName:""});
							throw(error);
						}
						
						var lineHeight:Float;
						var lineBase:Float;
						if ( config.ranges[index].line != null) {
							lineHeight = config.ranges[index].line.height / image.height * tilesY;
							lineBase = config.ranges[index].line.base / image.height * tilesY;
						}
						else if (config.line != null) {
							lineHeight = config.line.height / image.height * tilesY;
							lineBase = config.line.base / image.height * tilesY;
						}
						else {
							lineBase = lineHeight = 1;
						}
									
						// sort ranges into rangeMapping
						var range = config.ranges[index].range;
						
						${switch (glyphStyleHasMeta.multiTexture) {
							case true: macro {
								var p = textureCache.addImage(image, tilesX, tilesY); 
								//trace( image.width+"x"+image.height, "texture-unit:" + p.unit, "texture-slot:" + p.slot);							
								for (i in Std.int(range.min / rangeSize)...Std.int(range.max / rangeSize) + 1) {
									${switch (glyphStyleHasMeta.multiSlot) {
										case true: macro rangeMapping.set(i, {unit:p.unit, slot:p.slot, min:range.min, max:range.max, height:lineHeight, base:lineBase});
										default: macro rangeMapping.set(i, {unit:p.unit, min:range.min, max:range.max, height:lineHeight, base:lineBase});
									}}
								}
							}
							default: switch (glyphStyleHasMeta.multiSlot) {
								case true: macro {
									textureCache.setData(image, index);
									textureCache.tilesX = tilesX;
									textureCache.tilesY = tilesY;
									for (i in Std.int(range.min / rangeSize)...Std.int(range.max / rangeSize)+1) {
										rangeMapping.set(i, {slot:index, min:range.min, max:range.max, height:lineHeight, base:lineBase});
									}
								}
								default: macro {
									textureCache.setData(image, 0);
									textureCache.tilesX = tilesX;
									textureCache.tilesY = tilesY;
									rangeMapping = {min:range.min, max:range.max, height:lineHeight, base:lineBase};
								}
							}
						}}
					}
					
				}}	
					
			},
			function(images:Array<lime.graphics.Image>) { // after all images is loaded
				//trace(' --- all images loaded ---');
				onLoad(this);
			}
		);
		
	}
	
	// --------------------------- Embedding -------------------------
	
	// TODO
	
}

// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------
			
/*			if (glyphStyleHasMeta.gl3Font)
			{
				
				
				// ------ TODO: generate 
				if (glyphStyleHasMeta.multiTexture) {
					if (glyphStyleHasMeta.multiSlot) {
						
					}
					else {
					}
				}
				else {
					if (glyphStyleHasMeta.multiSlot) {
						
					}
					else {
						
					}
				}
				
			}
*/			

		return c;
	}
}
#end
