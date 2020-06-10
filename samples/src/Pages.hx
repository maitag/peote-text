package;
#if Pages
import haxe.Timer;

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

import peote.text.FontProgram;
import peote.text.Glyph;
//import peote.text.Range;

//import peote.text.GlyphStyle;
//import peote.text.Gl3GlyphStyle;

import peote.text.Line;
import peote.text.Page;

class Pages
{
	var peoteView:PeoteView;
	var display:Display;
	var timer:Timer;
	var helperLinesBuffer:Buffer<ElementSimple>;
	var helperLinesProgram:Program;
	
	public function new(window:Window)
	{
		try {	
			peoteView = new PeoteView(window.context, window.width, window.height);
			display   = new Display(10,10, window.width-20, window.height-20, Color.GREY1);
			peoteView.addDisplay(display);
			helperLinesBuffer = new Buffer<ElementSimple>(100);
			helperLinesProgram = new Program(helperLinesBuffer);
			display.addProgram(helperLinesProgram);
			
			var fontPacked = new Font<GlyphStylePacked>("assets/fonts/packed/hack/config.json");
			//var fontPacked = new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [new peote.text.Range(0x0000,0x0fff)]);
			//var fontPacked = new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json");
			//var fontPacked = new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [peote.text.Range.C0ControlsBasicLatin(), peote.text.Range.C1ControlsLatin1Supplement()]);

			var fontTiled = new Font<GlyphStyleTiled>("assets/fonts/tiled/hack_ascii.json");
			//var fontTiled = new Font<GlyphStyleTiled>("assets/fonts/tiled/liberation_ascii.json");
			//var fontTiled = new Font<GlyphStyleTiled>("assets/fonts/tiled/peote.json");
			
			fontPacked.load( function() {
			
				var fontStyle = new GlyphStylePacked();
				
				var fontProgram = new FontProgram<GlyphStylePacked>(fontPacked, fontStyle); // manage the Programs to render glyphes in different size/colors/fonts
				display.addProgram(fontProgram);
				
				var glyphStyle = new GlyphStylePacked();
				glyphStyle.width = fontPacked.config.width;
				glyphStyle.height = fontPacked.config.height;
				
				var glyphStyle1 = new GlyphStylePacked();
				glyphStyle1.color = Color.YELLOW;
				glyphStyle1.width = fontPacked.config.width * 1.0;
				glyphStyle1.height = fontPacked.config.height * 1.0;
				//glyphStyle1.zIndex = 1;
				//glyphStyle1.rotation = 22.5;
								
				// -------- Pages --------
				
				var page = fontProgram.createPage("hello\nworld\n\ntest", 0, 200, glyphStyle);
				
				Timer.delay(function() {
					var text = "Um einen Feuerball rast eine Kotkugel,\nauf der Damenseidenstrümpfe verkauft und Gauguins geschätzt werden.\n\n"
						     + "Ein fürwahr überaus betrüblicher Aspekt,\r\nder aber immerhin ein wenig unterschiedlich ist:\rSeidenstrümpfe können begriffen werden, Gauguins nicht.";
					fontProgram.setPage(page, text, 0, 200, glyphStyle);
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
			
		} catch (e:Dynamic) trace("ERROR:", e);
		// ---------------------------------------------------------------
	}

	public function addHelperLines(line:Line<GlyphStylePacked>) {
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
	
	public function onPreloadComplete ():Void {
		// sync loading did not work with html5!
		// texture.setImage(Assets.getImage("assets/images/wabbit_alpha.png"));
	}
	
	public function onMouseDown (x:Float, y:Float, button:MouseButton):Void
	{
		isZooming = ! isZooming;
	}
	
	public function onMouseMove (x:Float, y:Float):Void {}
	public function onMouseUp (x:Float, y:Float, button:MouseButton):Void {}

	public function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void
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

	public function render() peoteView.render();
	public function update(deltaTime:Int):Void {}

	public function onTextInput(text:String):Void {}
	public function onWindowActivate():Void {}
	public function onWindowLeave ():Void {}

	public function resize(width:Int, height:Int)
	{
		peoteView.resize(width, height);
		display.width  = width - 20;
		display.height = height - 20;
	}

}
#end