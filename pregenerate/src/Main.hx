package;

import haxe.macro.Context;
import haxe.macro.Tools.TExprTools;
#if macro
import haxe.macro.Expr;
import haxe.macro.Printer;
#end

import haxe.CallStack;
import sys.FileSystem;
import sys.io.File;

import lime.app.Application;

class Main extends Application
{	
	override function onWindowCreate():Void
	{
		switch (window.context.type)
		{
			case WEBGL, OPENGL, OPENGLES:
				try start()
				catch (_) trace(CallStack.toString(CallStack.exceptionStack()), _);
			default: throw("Sorry, only works with OpenGL.");
		}
	}

	public function start()
	{
		var map:Map<String,String>;


		// ------ GENERATE PACKED --------

		map = generate("P", "Packed", "peote.text.packed");

		// create directory
		if (!FileSystem.exists("packed")) FileSystem.createDirectory("packed");

		// save into files
		for (name => content in map) {
			trace('save packed/$name.hx');
			File.saveContent('packed/$name.hx',content);
		}


		// ------ GENERATE TILED --------

		map = generate("T", "Tiled", "peote.text.tiled");

		// create directory
		if (!FileSystem.exists("tiled")) FileSystem.createDirectory("tiled");

		// save into files
		for (name => content in map) {
			trace('save tiled/$name.hx');
			File.saveContent('tiled/$name.hx',content);
		}

	}



	macro static function generate(postfix:String, postfixStyle:String, p:String):Expr {
		#if macro
		// trace( postfix );
		// trace( pack );

		var pack = 'package $p;\n';

		var nameValueMap:Array<Expr> = [];
		
		var glyphTypeDef = peote.text.Glyph.GlyphMacro.getTypeDefinition(
			'Glyph$postfix', // className
			'peote.text', // styleModule
			'GlyphStyle$postfixStyle', // styleName
			TPath({ pack:['peote.text'], name:'GlyphStyle$postfixStyle', params:[] })  // styleType 
		);
		glyphTypeDef.meta = [ {name:":allow", params:[ Context.parse(p, Context.currentPos()) ], pos:Context.currentPos()} ];
		nameValueMap.push(macro $v{'Glyph$postfix'} => $v{pack + new Printer().printTypeDefinition(glyphTypeDef)});

		var pageLineTypeDef = peote.text.PageLine.PageLineMacro.getTypeDefinition(
			'PageLine$postfix', // className
			'peote.text', // styleModule
			'GlyphStyle$postfixStyle', // styleName
			TPath({ pack:[], name:'Glyph$postfix', params:[] })  // glyphType 
		);
		pageLineTypeDef.meta = [ {name:":allow", params:[ Context.parse(p, Context.currentPos()) ], pos:Context.currentPos()} ];
		nameValueMap.push(macro $v{'PageLine$postfix'} => $v{pack + new Printer().printTypeDefinition(pageLineTypeDef)});
		
		var lineTypeDef = peote.text.Line.LineMacro.getTypeDefinition(
			'Line$postfix', // className
			'peote.text', // styleModule
			'GlyphStyle$postfixStyle', // styleName
			TPath({ pack:[], name:'Glyph$postfix', params:[] }),  // glyphType 
			{ pack:[], name:'PageLine$postfix', params:[] }  // pageLinePath
		);
		lineTypeDef.meta = [ {name:":allow", params:[ Context.parse(p, Context.currentPos()) ], pos:Context.currentPos()} ];
		nameValueMap.push(macro $v{'Line$postfix'} => $v{pack + new Printer().printTypeDefinition(lineTypeDef)});
		
		var pageTypeDef = peote.text.Page.PageMacro.getTypeDefinition(
			'Page$postfix', // className
			'peote.text', // styleModule
			'GlyphStyle$postfixStyle', // styleName
			TPath({ pack:[], name:'PageLine$postfix', params:[] })  // pageLineType 
		);
		pageTypeDef.meta = [ {name:":allow", params:[ Context.parse(p, Context.currentPos()) ], pos:Context.currentPos()} ];
		nameValueMap.push(macro $v{'Page$postfix'} => $v{pack + new Printer().printTypeDefinition(pageTypeDef)});
		
		var fontTypeDef = peote.text.Font.FontMacro.getTypeDefinition(
			'Font$postfix', // className
			{ pack:['peote.text'], name:'GlyphStyle$postfixStyle', params:[] }, // stylePath
			[], // stylePack
			'peote.text', // styleModule
			'GlyphStyle$postfixStyle', // styleName
			TPath({ pack:['peote.text'], name:'GlyphStyle$postfixStyle', params:[] }),  // styleType
			TPath({ pack:[], name:'Glyph$postfix', params:[] }),  // glyphType
			TPath({ pack:[], name:'Line$postfix', params:[] }),  // lineType
			TPath({ pack:[], name:'Font$postfix', params:[] }),  // fontType
			TPath({ pack:[], name:'FontProgram$postfix', params:[] }),  // fontProgramType
			{ pack:[], name:'FontProgram$postfix', params:[] },  // fontProgramPath
			{ pack:[], name:'Glyph$postfix', params:[] },  // glyphPath
			{ pack:[], name:'Line$postfix', params:[] }  // linePath
		);
		nameValueMap.push(macro $v{'Font$postfix'} => $v{pack + "@:access(peote.text.FontConfig)\n" + new Printer().printTypeDefinition(fontTypeDef)});
		
		var fontProgramTypeDef = peote.text.FontProgram.FontProgramMacro.getTypeDefinition(
			'FontProgram$postfix', // className
			'peote.text', // styleModule
			'GlyphStyle$postfixStyle', // styleName
			TPath({ pack:['peote.text'], name:'GlyphStyle$postfixStyle', params:[] }),  // styleType
			TPath({ pack:[], name:'Glyph$postfix', params:[] }),  // glyphType
			TPath({ pack:[], name:'Line$postfix', params:[] }),  // lineType
			TPath({ pack:[], name:'PageLine$postfix', params:[] }),  // pageLineType
			TPath({ pack:[], name:'Font$postfix', params:[] }),  // fontType
			TPath({ pack:[], name:'Page$postfix', params:[] }),  // PageType
			{ pack:[], name:'Glyph$postfix', params:[] },  // glyphPath
			{ pack:[], name:'Line$postfix', params:[] },  // linePath
			{ pack:[], name:'PageLine$postfix', params:[] },  // pageLinePath
			{ pack:[], name:'Page$postfix', params:[] }  // pagePath
		);
		nameValueMap.push(macro $v{'FontProgram$postfix'} => $v{pack + "@:access(peote.text.FontConfig)\n" + new Printer().printTypeDefinition(fontProgramTypeDef)});
		
		return macro $a{nameValueMap};
		#end
	}


}
