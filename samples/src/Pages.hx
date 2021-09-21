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
import elements.ElementSimple;

import peote.text.Font;


class Pages extends Application
{
	var peoteView:PeoteView;
	var display:Display;
	var timer:Timer;
	var helperLinesBuffer:Buffer<ElementSimple>;
	var helperLinesProgram:Program;
	
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
		helperLinesBuffer = new Buffer<ElementSimple>(100);
		helperLinesProgram = new Program(helperLinesBuffer);
		display.addProgram(helperLinesProgram);
		
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
			glyphStyle1.width = font.config.width * 1.0;
			glyphStyle1.height = font.config.height * 1.0;
			//glyphStyle1.zIndex = 1;
			//glyphStyle1.rotation = 22.5;
							
			// -------- Pages --------
			
			var page = fontProgram.createPage("hello\nworld\n\ntest", 10, 10, glyphStyle);
			
			Timer.delay(function() {
				var text = "Um einen Feuerball rast eine Kotkugel,\nauf der Damenseidenstrümpfe verkauft und Gauguins geschätzt werden.\n\n"
						 + "Ein fürwahr überaus betrüblicher Aspekt,\r\nder aber immerhin ein wenig unterschiedlich ist:\rSeidenstrümpfe können begriffen werden, Gauguins nicht.";
				fontProgram.setPage(page, text, 10, 10, glyphStyle);
			}, 1000);
			
			/*
			Timer.delay(function() {
				fontProgram.pageInsertLine(page, "(Bernheim als prestigieuser Biologe zu imaginieren.)", 2 , glyphStyle2);
			}, 2000);

			Timer.delay(function() {
				fontProgram.pageDeleteLine(page, 1);
			}, 3000);

			Timer.delay(function() {
				fontProgram.pageSetLine(page, 2, "TEST");
			}, 4000);
			
			Timer.delay(function() {
				fontProgram.removePage(page);
			}, 5000);
			
			Timer.delay(function() {
				fontProgram.addPage(page);
			}, 6000);
			
			
			// -- lines inside --

			Timer.delay(function() {
				var line = page.getLine(0);
				fontProgram.lineInsertChars(line, "Walther " 0, 2, glyphStyle2);
				fontProgram.lineInsertChar(line, ":" , glyphStyle2);
				fontProgram.updateLine(line);
			}, 7000);
			
			
			
			*/
		});

		
		
		
		timer = new Timer(40); zoomIn();
			
	}

/*	public function addHelperLines(line:Line<GlyphStylePacked>) {
		helperLinesBuffer.addElement(new ElementSimple(Std.int(line.x), Std.int(line.y), Std.int(line.maxX-line.x), Std.int(line.maxY-line.y), Color.GREY3));
		// top line
		helperLinesBuffer.addElement(new ElementSimple(Std.int(line.x), Std.int(line.y), Std.int(line.maxX-line.x), 1, Color.BLUE));				
		// ascender line
		helperLinesBuffer.addElement(new ElementSimple(Std.int(line.x), Std.int(line.y + line.asc), Std.int(line.maxX-line.x), 1, Color.YELLOW));
		// baseline
		helperLinesBuffer.addElement(new ElementSimple(Std.int(line.x), Std.int(line.y + line.base), Std.int(line.maxX-line.x), 1, Color.RED));
		// descender line
		helperLinesBuffer.addElement(new ElementSimple(Std.int(line.x), Std.int(line.maxY), Std.int(line.maxX-line.x), 1, Color.GREEN));
	}
*/	
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