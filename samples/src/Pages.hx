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

class Pages extends Application
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
		
		new Font<GlyphStylePacked>("assets/fonts/packed/hack/config.json")
		//new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [new peote.text.Range(0x0000,0x0fff)])
		//new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json")
		//new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [peote.text.Range.C0ControlsBasicLatin(), peote.text.Range.C1ControlsLatin1Supplement()])
		//new Font<GlyphStyleTiled>("assets/fonts/tiled/hack_ascii.json")
		//new Font<GlyphStyleTiled>("assets/fonts/tiled/liberation_ascii.json")
		//new Font<GlyphStyleTiled>("assets/fonts/tiled/peote.json")
		
		.load( function(font) {
		
			var fontStyle = font.createFontStyle();
			
			//var fontProgram = new FontProgram<GlyphStylePacked>(font, fontStyle); // manage the Programs to render glyphes in different size/colors/fonts
			var fontProgram = font.createFontProgram(fontStyle);
			display.addProgram(fontProgram);
			
			var glyphStyle = font.createFontStyle();
			glyphStyle.width = font.config.width;
			glyphStyle.height = font.config.height;
			
			var glyphStyle1 = font.createFontStyle();
			glyphStyle1.color = Color.YELLOW;
			glyphStyle1.width = font.config.width * 0.8;
			glyphStyle1.height = font.config.height * 0.8;
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

			var page = fontProgram.createPage("hello world", 30, 30, 500, null, 0, 0, glyphStyle);
			//var page = fontProgram.createPage("hello world", 30, 30, 500, 100, 0, 0, glyphStyle);
			
			// helper tp show visible area
			var buffer = new Buffer<HelperElement>(1);
			var helperProgram = new Program(buffer);
			var helper = new HelperElement(page.x, page.y, page.width, page.textHeight, Color.BLUE);
			buffer.addElement(helper);
			display.addProgram(helperProgram, true);

			Timer.delay(function() {
				var text = "Um einen Feuerball rast eine Kotkugel,\n"
						+"auf der Damenseidenstrümpfe verkauft und Gauguins geschätzt werden."
						+"\n"
						+ "Ein fürwahr überaus betrüblicher Aspekt,\r\nder aber immerhin ein wenig unterschiedlich ist:\rSeidenstrümpfe können begriffen werden, \nGauguins nicht."
						;
				fontProgram.pageSet(page, text, glyphStyle1);
				//fontProgram.pageSet(page, text, 10, 10, glyphStyle);
				
				trace("after pageSet:",page.updateLineFrom, page.updateLineTo);
				fontProgram.pageUpdate(page);
				
				helper.h = page.textHeight; buffer.updateElement(helper);
			}, 1000);
			

/*			Timer.delay(function() {
				fontProgram.pageSetPosition(page, 50, 50, 0, 0);
				//fontProgram.pageSetXPosition(page, 5, -5, -10);
				//fontProgram.pageSetYPosition(page, 5, -5, -10);
				//fontProgram.pageSetPositionSize(page, 5, 5, 500, 100, -5, -10);
				//fontProgram.pageSetSize(page, 500, 235, -20, 0);
				//fontProgram.pageSetOffset(page, 10, -20);
				//fontProgram.pageSetXOffset(page, -20);
				//fontProgram.pageSetYOffset(page, -20);
				
				fontProgram.pageUpdate(page);
				helper.x = page.x; helper.y = page.y; helper.w = page.width;
				//helper.h = page.height;
				helper.h = page.textHeight;
				buffer.updateElement(helper);
			}, 2000);
			
			Timer.delay(function() {//TODO
				fontProgram.pageAppendChars(page, "(Bernheim als prestigieuser Biologe zu imaginieren.)\nTESTA\nTESTB 123456789\nTESTC\n" , glyphStyle);
				fontProgram.pageAppendChars(page, "TESTD" , glyphStyle);
				
				helper.h = page.textHeight; buffer.updateElement(helper);
			}, 3000);

*/			Timer.delay(function() {//TODO
				fontProgram.pageInsertChars(page, "INSERTION over MANY LINES\nis on a good   \\o/\nWAY ", 4, 9 , glyphStyle);
				trace("after pageInsertChars:",page.updateLineFrom, page.updateLineTo);
				
				fontProgram.pageUpdate(page);
				
				helper.h = page.textHeight; buffer.updateElement(helper);
			}, 2000);

/*			Timer.delay(function() {//TODO
				fontProgram.pageInsertLine(page, 2, "(Bernheim als prestigieuser Biologe zu imaginieren.)" , glyphStyle);
			}, 4000);

			Timer.delay(function() {//TODO
				fontProgram.pageDeleteLine(page, 2);
			}, 5000);
*/						

/*			Timer.delay(function() {
				fontProgram.pageRemove(page);
			}, 6000);
			
			Timer.delay(function() {
				fontProgram.pageAdd(page);
			}, 7000);
*/			
			
			// -- edit a pageLine inside --

/*			Timer.delay(function() {
				var pageLine = page.getPageLine(0);
				fontProgram.pageLineInsertChars(pageLine, page.x, page.width, page.xOffset, "Walther ", 3, glyphStyle);
				fontProgram.pageLineInsertChar(pageLine, page.x, page.width, page.xOffset, ":".charCodeAt(0), 10 , glyphStyle);
				fontProgram.pageLineUpdate(pageLine);
			}, 6000);
*/			
			
			
			
		});

		
		
		
		timer = new Timer(40); zoomIn();
			
	}

	var isZooming:Bool = false;
	public function zoomIn() {
		var fz:Float = 1.0;		
		timer.run = function() {
			if (isZooming) {
				if (fz < 10.0) fz *= 1.01; else zoomOut();
				display.zoom = fz;
			}
		}
	}
	
	public function zoomOut() {
		var fz:Float = 10.0;
		timer.run = function() {
			if (isZooming) {
				if (fz > 1.0) fz /= 1.01; else zoomIn();
				display.zoom = fz;
			}
		}
	}
	
	override function onMouseDown (x:Float, y:Float, button:MouseButton):Void
	{
		isZooming = ! isZooming;
	}
	
	override function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void
	{	
		switch (keyCode) {
			case KeyCode.NUMPAD_PLUS:
					if (modifier.shiftKey) peoteView.zoom+=0.01;
					else display.zoom+=0.1;
			case KeyCode.NUMPAD_MINUS:
					if (modifier.shiftKey) peoteView.zoom-=0.01;
					else display.zoom -= 0.1;
			
			case KeyCode.UP: display.yOffset -= (modifier.shiftKey) ? 8 : 1;
			case KeyCode.DOWN: display.yOffset += (modifier.shiftKey) ? 8 : 1;
			case KeyCode.RIGHT: display.xOffset += (modifier.shiftKey) ? 8 : 1;
			case KeyCode.LEFT: display.xOffset -= (modifier.shiftKey) ? 8 : 1;
			default:
		}
	}

	override function onWindowResize(width:Int, height:Int)
	{
		display.width  = width - 20;
		display.height = height - 20;
	}

}