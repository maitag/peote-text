package;

import haxe.Timer;
import haxe.CallStack;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Buffer;
import peote.view.Program;
import peote.view.Color;
import peote.view.Element;

import peote.text.Font;
import peote.text.packed.FontP;
import peote.text.FontProgram;

import peote.text.GlyphStylePacked;

class HelperElement implements Element
{
	@posX public var x:Float;
	@posY public var y:Float;
	@sizeX public var w:Float;
	@sizeY public var h:Float;	
	@color public var c:Color;	
	public function new(x:Float, y:Float, w:Float, h:Float, c:Color) {
		this.x = x; this.y = y; this.w = w; this.h = h; this.c = c;
	}
}

class PageWrapping extends Application
{
	var peoteView:PeoteView;
	var display:Display;
	var timer:Timer;
	
	override function onWindowCreate():Void
	{
		switch (window.context.type)
		{
			case WEBGL, OPENGL, OPENGLES:
				try startSample(window)
				catch (_) trace(CallStack.toString(CallStack.exceptionStack()), _);
			default: throw("Sorry, only works with OpenGL.");
		}
	}

	public function startSample(window:Window)
	{
		peoteView = new PeoteView(window);
		display   = new Display(10,10, window.width-20, window.height-20, Color.GREY1);
		peoteView.addDisplay(display);
		
		// new Font<GlyphStylePacked>("assets/fonts/packed/hack/config.json")
		new FontP("assets/fonts/packed/hack/config.json")

		// glitch: if in config.json the range is start by zero but charcodes starts with 32

		// new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [new peote.text.Range(0x0000,0x0fff)])
		// new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json")
		// new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [peote.text.Range.C0ControlsBasicLatin(), peote.text.Range.C1ControlsLatin1Supplement()])
		// new Font<GlyphStyleTiled>("assets/fonts/tiled/hack_ascii.json")
		// new Font<GlyphStyleTiled>("assets/fonts/tiled/liberation_ascii.json")
		// new Font<GlyphStyleTiled>("assets/fonts/tiled/peote.json")
		
		.load( function(font) {
		
			var fontStyle = font.createFontStyle();
			
			// var fontProgram = new FontProgram<GlyphStylePacked>(font, fontStyle); // manage the Programs to render glyphes in different size/colors/fonts
			var fontProgram = new peote.text.packed.FontProgramP(font, fontStyle); // manage the Programs to render glyphes in different size/colors/fonts
			// var fontProgram = font.createFontProgram(fontStyle);
			display.addProgram(fontProgram);
			
			var glyphStyle = font.createFontStyle();
			glyphStyle.width = font.config.width;
			glyphStyle.height = font.config.height;
			
			var glyphStyle1 = font.createFontStyle();
			glyphStyle1.color = Color.YELLOW;
			glyphStyle1.width = font.config.width * 0.5;
			glyphStyle1.height = font.config.height * 0.5;
			//glyphStyle1.zIndex = 1;
			//glyphStyle1.rotation = 22.5;
							
			// -------- Pages --------			
			
			var numberOfUnrecognizedChars = 0;
			var unrecognizedChars:String = "";
			var onUnrecognizedChar = (charcode:Int, lineNumber:Int, position:Int)->{
				trace('unrecognized Char:$charcode at lineNumber:$lineNumber and position:$position');
				numberOfUnrecognizedChars++;
				unrecognizedChars += " " + StringTools.hex(charcode);
			}

			var text =   "Um einen Feuerball rast eine Kotkugel,\n"
						+"auf der Damenseidenstrümpfe verkauft und Gauguins geschätzt werden."
						        +" 0123456789 0123456789 abcd efgh  abc "
								+"ABC----------------------------------------------------------"
						        +"\n"
						+ "Ein fürwahr überaus betrüblicher Aspekt, der aber immerhin ein wenig unterschiedlich ist: Seidenstrümpfe können begriffen werden, Gauguins nicht."
						;
			//var page = fontProgram.createPage(text, 30, 30, 500, null, 0, 0, glyphStyle);
			var page = fontProgram.createPage(text, 30, 30, 517, 200, 0, 0, glyphStyle);
			//trace('textWidth=${page.textWidth}\nlongestLines=${page.longestLines}');
			trace('textWidth=${page.textWidth}');
			
			// helper tp show visible area
			var buffer = new Buffer<HelperElement>(1);
			var helperProgram = new Program(buffer);
			//var helper = new HelperElement(page.x, page.y, page.width, page.textHeight, Color.BLUE);
			var helper = new HelperElement(page.x, page.y, page.width, page.height, Color.BLUE);
			buffer.addElement(helper);
			display.addProgram(helperProgram, true);
			
			Timer.delay(function() {
				trace("old amount of lines into page:", page.length);
				var numWrapped = fontProgram.pageWrapLine(page, 1, false, false, glyphStyle);
				trace("numwrapped:", numWrapped);
				trace("new amount of lines into page:", page.length);
				//trace('textWidth=${page.textWidth}\nlongestLines=${page.longestLines}');
				
				fontProgram.pageUpdate(page);
				//helper.h = page.textHeight; buffer.updateElement(helper);
			}, 2000);
			
			
		});

		
			
	}


}