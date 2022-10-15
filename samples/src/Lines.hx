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
import peote.view.Program;
import peote.view.Buffer;
import peote.view.Element;
import peote.view.Color;

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

class Lines extends Application
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
		//new Font<GlyphStyleTiled>("assets/fonts/tiled/hack_ascii.json")
		//new Font<GlyphStyleTiled>("assets/fonts/tiled/liberation_ascii.json")
		//new Font<GlyphStyleTiled>("assets/fonts/tiled/peote.json")
		
		.load( function(font) {
			//var fontStyle = new GlyphStyleType();
			var fontStyle = font.createFontStyle();
			
			//var fontProgram = new FontProgramType(font, fontStyle); // manage the Programs to render glyphes in different size/colors/fonts
			var fontProgram = font.createFontProgram(fontStyle);
			display.addProgram(fontProgram);
			
			//var glyphStyle = new GlyphStyleType();
			var glyphStyle = font.createFontStyle();
			glyphStyle.width = font.config.width;
			glyphStyle.height = font.config.height;
			
			//var glyphStyle1 = new GlyphStyleType();
			var glyphStyle1 = font.createFontStyle();
			glyphStyle1.color = Color.YELLOW;
			glyphStyle1.width = font.config.width * 1.0;
			glyphStyle1.height = font.config.height * 1.0;								
			
			// -----------
			
			//var glyphStyle2 = new GlyphStyleType();
			var glyphStyle2 = font.createFontStyle();
			glyphStyle2.color = Color.RED;
			glyphStyle2.width = font.config.width * 2.0;
			glyphStyle2.height = font.config.height * 2.0;
			
			
			// ------------------- Lines  -------------------
			
			//var tilted = new GlyphStyleType();
			var tilted = font.createFontStyle();
			tilted.tilt = 0.4;
			tilted.color = 0xaabb22ff;
			tilted.width = font.config.width;
			tilted.height = font.config.height;
			fontProgram.lineSet(font.createLine(), "tilted", 0, 50, tilted);
			
			//var thick = new GlyphStyleType();
			var thick = font.createFontStyle();
			thick.weight = 0.45; // TODO
			thick.width = font.config.width;
			thick.height = font.config.height;
			fontProgram.lineSet(font.createLine(), "bold", 150, 50, thick);
			
			var line = fontProgram.createLine("hello World :)", 0, 100, glyphStyle);
			
			//fontProgram.getMetric();
			
			//TODO: line.setGlyphOffset(0, 3  , 5, 6);
			//TODO: line.getGlyph(2);
			
			Timer.delay(function() {
				fontProgram.lineSet(line, "hello World (^_^)", line.x, line.y, glyphStyle);
				fontProgram.lineUpdate(line);
			}, 1000);
			
			Timer.delay(function() {
				fontProgram.lineSetStyle(line, glyphStyle2, 1, 5);
				fontProgram.lineSetStyle(line, glyphStyle1, 6, 12);
				
				//fontProgram.lineUpdate(line, 6);
				//trace('visibleFrom: ${line.visibleFrom} visibleTo:${line.visibleTo} fullWidth:${line.fullWidth}');
				//fontProgram.lineSetPosition(line, 0, 130);
				
				fontProgram.lineSetYPosition(line, 130);
				fontProgram.lineUpdate(line);
			}, 2000);
			
			Timer.delay(function() {
				fontProgram.lineSetChar(line, "H".charCodeAt(0) , 0, glyphStyle2); // replace existing char into line
				fontProgram.lineSetChars(line, "Planet", 6);  // replace existing chars into line
				fontProgram.lineUpdate(line);
			}, 3000);

			Timer.delay(function() {
				fontProgram.lineInsertChar(line, "~".charCodeAt(0) , 12, glyphStyle1);
				fontProgram.lineInsertChars(line,  "Earth", 12, glyphStyle2);
				fontProgram.lineUpdate(line);
			}, 4000);
							
			Timer.delay(function() {
				fontProgram.lineDeleteChar(line, 5);
				fontProgram.lineUpdate(line);
			}, 5000);
			
			Timer.delay(function() {
				fontProgram.lineDeleteChars(line, 16);
				//fontProgram.lineDeleteChars(line, 0);
				//fontProgram.lineSetOffset(line, -10);
				//fontProgram.lineAppendChars(line, "test append");
				fontProgram.lineUpdate(line);
			}, 6000);
			
			Timer.delay(function() {
				fontProgram.lineRemove(line);
			}, 7000);
			
			Timer.delay(function() {
				fontProgram.lineAdd(line);
			}, 8000);
		
			// TODO:
			// line.clear();		

			
			// -------- testing offsets and new line.textSize ----------
			
			var buffer = new Buffer<HelperElement>(1);
			var helperProgram = new Program(buffer);
			
			var line1 = fontProgram.createLine("test textsize", 100, 200, null, 30, glyphStyle);
			var helper = new HelperElement(line1.x, line1.y, line1.textSize, line1.height, Color.BLUE);
			buffer.addElement(helper);
			display.addProgram(helperProgram, true);
						
			Timer.delay(function() {
				//var offset = fontProgram.lineSetStyle(line1, glyphStyle2, 0, 4);
				//var offset = fontProgram.lineSetStyle(line1, glyphStyle2, 1, 4);
				//var offset = fontProgram.lineSetStyle(line1, glyphStyle2, 12, 13);
				//var offset = fontProgram.lineSetStyle(line1, glyphStyle2);
				
				//var offset = fontProgram.lineSetChar(line1, "A".charCodeAt(0) , 0, glyphStyle2); 
				//var offset = fontProgram.lineSetChar(line1, "A".charCodeAt(0) , 1, glyphStyle2); 
				//var offset = fontProgram.lineSetChar(line1, "A".charCodeAt(0) , 12, glyphStyle2); 
				
				//var offset = fontProgram.lineSetChars(line1, "AB" , 0, glyphStyle2);
				//var offset = fontProgram.lineSetChars(line1, "AB" , 1, glyphStyle2);
				var offset = fontProgram.lineSetChars(line1, "TEST TEXTSIZE 123", 0, glyphStyle2);
				//var offset = fontProgram.lineSetChars(line1, "AB", 11, glyphStyle2);
				
				//var offset = fontProgram.lineAppendChars(line1, "123", glyphStyle2);
				
				//var offset = fontProgram.lineDeleteChar(line1, 0);
				//var offset = fontProgram.lineDeleteChar(line1, 1);
				//var offset = fontProgram.lineDeleteChar(line1, 12);
				
				//var offset = fontProgram.lineDeleteChars(line1, 0, 2);
				//var offset = fontProgram.lineDeleteChars(line1, 1, 3);
				//var offset = fontProgram.lineDeleteChars(line1, 11, 13);
				//var offset = fontProgram.lineDeleteChars(line1, 0, 13);
				
				//var offset = fontProgram.lineInsertChar(line1, "A".charCodeAt(0), 0, glyphStyle2);
				//var offset = fontProgram.lineInsertChar(line1, "A".charCodeAt(0), 1, glyphStyle2);
				//var offset = fontProgram.lineInsertChar(line1, "A".charCodeAt(0), 13, glyphStyle2);
				
				//var offset = fontProgram.lineInsertChars(line1, "AB", 0, glyphStyle2);
				//var offset = fontProgram.lineInsertChars(line1, "AB", 1, glyphStyle2);
				//var offset = fontProgram.lineInsertChars(line1, "AB", 13, glyphStyle2);
				
				//helper.w = line1.textSize;
				helper.w += offset;
				
				buffer.updateElement(helper);
				fontProgram.lineUpdate(line1);
			}, 1000);

			Timer.delay(function() {
				fontProgram.lineSetOffset(line1, 0);
				fontProgram.lineUpdate(line1);
			}, 2000);
			
			// -------- testing if chars is not inside of Font ----------
			
			var numberOfUnrecognizedChars = 0;
			var unrecognizedChars:String = "";
			// callback to detect chars that not is inside of font
			var onUnrecognizedChar = (charcode:Int, position:Int)->{
				trace('unrecognized Char:$charcode after position:$position');
				numberOfUnrecognizedChars++;
				unrecognizedChars += " " + StringTools.hex(charcode);
			}
			// TODO: bug into 
			// 500 -> neko ok, hashlink don't show character
			// 
			var line2 = fontProgram.createLine(""
				
				//+ String.fromCharCode(0x1F) // <- unrecognized char
				
				+ String.fromCharCode(0x20) // first one (space)
				
				+"ö" 
				//+ String.fromCharCode(246) // <- should be "ö" also ( encoding not work on neko!)
				
				+"⸥"
				//+ String.fromCharCode(0x2e25) // <- should be "⸥" also ( encoding not work on neko!)
				
				//+ String.fromCharCode(0x1F4) // <- unrecognized char ( encoding stops on neko!)
				
				// + String.fromCharCode(0x2e26) // <- unrecognized char (but not on neko, there it gives wron encoded char!)
				// + "test"
				
				, 0, 300, glyphStyle2, onUnrecognizedChar);
				
			trace("--------------------");
			
			//fontProgram.lineSetChar(line2, 0x1F, 2, onUnrecognizedChar);
			
			//fontProgram.lineSetChars(line2, "abc"+ String.fromCharCode(0x1F), 1, onUnrecognizedChar);
			
			//fontProgram.lineInsertChar(line2, 0x1F, 2, onUnrecognizedChar);
			//fontProgram.lineInsertChars(line2, "a"+ String.fromCharCode(0x1F), 2, onUnrecognizedChar);
			
			//fontProgram.lineAppendChars(line2, "a"+ String.fromCharCode(0x1F), onUnrecognizedChar);
			
			//fontProgram.lineUpdate(line2);
			
			if (numberOfUnrecognizedChars != 0) fontProgram.createLine("unrecognized charcodes:"+unrecognizedChars, 0, 350, glyphStyle1);
			
		}
		, true // debug
		);
		
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