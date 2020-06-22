package;
#if Fonts
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

class Fonts
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
			
			// --------------------------------------------------------
			
			var packedFonts = [
				{ name: "hack",    y:  30, range: null },
				{ name: "unifont", y: 100, range: [new peote.text.Range(0x0000,0x0fff)] }
			];

			for (f in packedFonts) 
			{
				var font = new Font<GlyphStylePacked>('assets/fonts/packed/${f.name}/config.json', f.range);
				font.load( function()
				{
					var glyphStyle = new GlyphStylePacked();
					glyphStyle.width = font.config.width * 1.0;
					glyphStyle.height = font.config.height * 1.0;								
					
					var fontProgram = new FontProgram<GlyphStylePacked>(font, glyphStyle);
					display.addProgram(fontProgram);
					
					var line = fontProgram.createLine('ÄABC defg (${f.name})', 0, f.y);

					glyphStyle.color = Color.YELLOW;
					glyphStyle.width = font.config.width * 2.0;
					glyphStyle.height = font.config.height * 2.0;								
													
					fontProgram.lineSetStyle(line, glyphStyle, 2, 3);
					fontProgram.updateLine(line);			
					
					//var range = font.getRange("a".charCodeAt(0));trace(range);
					addHelperLines(Std.int(line.x), Std.int(line.y), Std.int(line.fullWidth), Std.int(line.lineHeight), Std.int(line.height), Std.int(line.base));					
				});
				
			}
			
			// --------------------------------------------------------
			
			var tiledFonts = [
				{ name: "hack_ascii",       y:  200, range: null },
				{ name: "liberation_ascii", y:  300, range: null },
				{ name: "peote",            y:  400, range: null }
			];
			
			for (f in tiledFonts) 
			{
				var font = new Font<GlyphStyleTiled>('assets/fonts/tiled/${f.name}.json', f.range);
				font.load( function()
				{
					var glyphStyle = new GlyphStyleTiled();
					glyphStyle.width = font.config.width;
					glyphStyle.height = font.config.height;								
					
					var fontProgram = new FontProgram<GlyphStyleTiled>(font, glyphStyle);
					display.addProgram(fontProgram);
					
					var line = fontProgram.createLine('ABC defg (${f.name})', 0, f.y);					
					
					glyphStyle.color = Color.YELLOW;
					glyphStyle.width = font.config.width * 2.0;
					glyphStyle.height = font.config.height * 2.0;								
													
					fontProgram.lineSetStyle(line, glyphStyle, 2, 3);
					fontProgram.updateLine(line);
					
					addHelperLines(Std.int(line.x), Std.int(line.y), Std.int(line.fullWidth), Std.int(line.lineHeight), Std.int(line.height), Std.int(line.base));
				});
				
			}
			

			
			timer = new Timer(40); zoomIn();
			
		} catch (e:Dynamic) trace("ERROR:", e);
		// ---------------------------------------------------------------
	}

	public function addHelperLines(x:Int, y:Int, w:Int, lineHeight:Int, height:Int, base:Int) {
		helperLinesBuffer.addElement(new ElementSimple(x,     y, w, lineHeight, Color.GREY2));
		// baseline
		helperLinesBuffer.addElement(new ElementSimple(x, y+base, w, 1, Color.RED));
		// descender line
		helperLinesBuffer.addElement(new ElementSimple(x, y+height, w, 1, Color.BLUE));
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