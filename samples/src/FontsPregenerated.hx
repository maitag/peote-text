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
import peote.view.Color;

import peote.text.packed.FontP;
import peote.text.packed.FontProgramP;
import peote.text.GlyphStylePacked;

import peote.text.tiled.FontT;
import peote.text.tiled.FontProgramT;
import peote.text.GlyphStyleTiled;

import peote.text.Range;

import peote.text.skin.simple.SimpleSkinProgram;
import peote.text.skin.simple.SimpleSkinElement;

class FontsPregenerated extends Application
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
		
		// --------------------------------------------------------
		
		var packedFonts = [
			{ name: "hack",    y:  10, range: null },
			{ name: "unifont", y:  100, range: [new Range(0x0000,0x0fff)] }
		];

		for (f in packedFonts) 
		{
			new FontP('assets/fonts/packed/${f.name}/config.json', f.range).load( function(font)
			{
				var glyphStyle = new GlyphStylePacked();
				glyphStyle.width = 28;// font.config.width * 1.0;
				glyphStyle.height = 28;// font.config.height * 1.0;								
				
				var fontProgram = new FontProgramP(font, glyphStyle);
				// alternative way:
				// var fontProgram = font.createFontProgram(glyphStyle, false);
				
				display.addProgram(fontProgram);
				
				var line = fontProgram.createLine('ABC defg (packed: ${f.name}) ÄÖÜäöüß', 0, f.y);

				glyphStyle.color = Color.YELLOW;
				//glyphStyle.bgColor = Color.RED;
				glyphStyle.width = 56;// font.config.width * 2.0;
				glyphStyle.height = 56;// font.config.height * 2.0;
				fontProgram.lineSetStyle(line, glyphStyle, 2, 3);
				fontProgram.lineUpdate(line);			
				
				//var range = font.getRange("a".charCodeAt(0));trace(range);
				
				// helper lines via skin			
				var helperLinesProgram = fontProgram.addSkin( new SimpleSkinProgram(), -1 );
				
				var backgroundElement = new SimpleSkinElement(Color.GREY2);
				fontProgram.skinElemToLine(helperLinesProgram, backgroundElement, line, false);
				helperLinesProgram.addElement(backgroundElement);
				
				
				helperLinesProgram.addElement( // baseline
					new SimpleSkinElement(Color.RED, Std.int(line.x),  Std.int(line.y + line.base), Std.int(line.textSize), 1)
				);
				helperLinesProgram.addElement( // descender line
					new SimpleSkinElement(Color.BLUE, Std.int(line.x),  Std.int(line.y + line.height), Std.int(line.textSize), 1)
				);
				helperLinesProgram.addElement( // lineHeight (where next line starts)
					new SimpleSkinElement(Color.GREY4, Std.int(line.x),  Std.int(line.y + line.lineHeight), Std.int(line.textSize), 1)
				);
				
			},
			true // debug
			);
			
		}
		
		// --------------------------------------------------------
		
		var tiledFonts = [
			{ name: "hack_ascii",       y:  200, range: null },
			{ name: "liberation_ascii", y:  300, range: null },
			{ name: "peote",            y:  400, range: null }
		];
		
		for (f in tiledFonts) 
		{
			new FontT('assets/fonts/tiled/${f.name}.json', f.range).load(function(font)
			{
				var glyphStyle = new GlyphStyleTiled();
				glyphStyle.width = font.config.width;
				glyphStyle.height = font.config.height;								
				
				// var fontProgram = new FontProgram<GlyphStyleTiled>(font, glyphStyle);
				// alternative way to create the FontProgram<GlyphStylePacked>:
				var fontProgram = font.createFontProgram(glyphStyle, false);
				
				display.addProgram(fontProgram);
				
				var line = fontProgram.createLine('ABC defg (tiled: ${f.name})', 0, f.y);				
				
				glyphStyle.color = Color.YELLOW;
				//glyphStyle.bgColor = Color.RED;
				glyphStyle.width = font.config.width * 2.0;
				glyphStyle.height = font.config.height * 2.0;								
												
				fontProgram.lineSetStyle(line, glyphStyle, 2, 3);
				fontProgram.lineUpdate(line);
				
				// helper lines via skin				
				var helperLinesProgram = fontProgram.addSkin( new SimpleSkinProgram(), -1 );
				
				var backgroundElement = new SimpleSkinElement(Color.GREY2);
				fontProgram.skinElemToLine(helperLinesProgram, backgroundElement, line, false);
				helperLinesProgram.addElement(backgroundElement);
								
				helperLinesProgram.addElement( // baseline
					new SimpleSkinElement(Color.RED, Std.int(line.x),  Std.int(line.y + line.base), Std.int(line.textSize), 1)
				);
				helperLinesProgram.addElement( // descender line
					new SimpleSkinElement(Color.BLUE, Std.int(line.x),  Std.int(line.y + line.height), Std.int(line.textSize), 1)
				);
				helperLinesProgram.addElement( // lineHeight (where next line starts)
					new SimpleSkinElement(Color.GREY4, Std.int(line.x),  Std.int(line.y + line.lineHeight), Std.int(line.textSize), 1)
				);
				
			},
			true // debug
			);
		}
		
				
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