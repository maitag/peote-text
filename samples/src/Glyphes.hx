package;
#if Glyphes
import haxe.Timer;

import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Color;

import peote.text.Font;
import peote.text.FontProgram;
import peote.text.Glyph;
//import peote.text.Range;

//import peote.text.GlyphStyle;
//import peote.text.Gl3GlyphStyle;

//@multiSlot    // multiple slots per texture to store multiple unicode-ranges
//@multiTexture // multiple textures to store multiple unicode-ranges
// TODO:
//@maskX @maskY // cutting the first and last glyph into line if it is outside of offset and max
//@useInt       // using Integer for all glyphpositions and -sizes
class GlyphStyle {
	//@global public var color:Color = Color.BLUE;
	public var color:Color = Color.GREEN;
	
	//@global public var width:Float = 10.0;
	public var width:Float = 16;
	//@global public var height:Float = 16.0;
	public var height:Float = 16;
	
	//@global public var zIndex:Int = 0;
	//public var zIndex:Int = 0;
	
	//@global public var rotation:Float = 90;
	//public var rotation:Float = 0;
	
	//@global public var tilt:Float = 0.5;
	public var tilt:Float = 0.0;
	
	//@global public var weight = 0.48;
	public var weight:Float = 0.5;
	
	// TODO: additional spacing after each letter
	//@global public var letterSpacing:Float = 0.0;
	//public var letterSpacing:Float = 2.0;
	
	// TODO: for adjusting Glyphes inside Line
	// letterSpace
	
	// TODO: bgColor:Color = Color.ORANGE
	// TODO: outline/glow for distance field fonts
	
	public function new() {}
}

@packed
class GlyphStylePacked { //TODO: extends GlyphStyle {
	public var color:Color = Color.GREEN;
	public var width:Float = 16;
	public var height:Float = 16;
	public var tilt:Float = 0.0;
	public var weight:Float = 0.5;
	public function new() {}
}

class Glyphes
{
	var peoteView:PeoteView;
	var display:Display;
	var timer:Timer;
	
	public function new(window:Window)
	{
		try {	
			peoteView = new PeoteView(window.context, window.width, window.height);
			display   = new Display(10,10, window.width-20, window.height-20, Color.GREY1);
			peoteView.addDisplay(display);
			
			new Font<GlyphStylePacked>("assets/fonts/packed/hack/config.json")
			//new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [new peote.text.Range(0x0000,0x0fff)])
			//new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json")
			//new Font<GlyphStylePacked>("assets/fonts/packed/unifont/config.json", [peote.text.Range.C0ControlsBasicLatin(), peote.text.Range.C1ControlsLatin1Supplement()])
			//new Font<GlyphStyle>("assets/fonts/tiled/hack_ascii.json")
			//new Font<GlyphStyle>("assets/fonts/tiled/liberation_ascii.json")
			//new Font<GlyphStyle>("assets/fonts/tiled/peote.json")
			.load( function(font) {
			
				//var gl3font = fontPacked.getRange(65);
				
				//var fontStyle = new GlyphStyle();
				var fontStyle = font.createFontStyle();
				
				//var fontProgram = new FontProgram<GlyphStyle>(font, fontStyle); // manage the Programs to render glyphes in different size/colors/fonts
				var fontProgram = font.createFontProgram(fontStyle); 
				display.addProgram(fontProgram);
				
				//var glyphStyle = new GlyphStyle();
				var glyphStyle = font.createFontStyle();
				glyphStyle.width = font.config.width;
				glyphStyle.height = font.config.height;
				
				//var glyphStyle1 = new GlyphStyle();
				var glyphStyle1 = font.createFontStyle();
				glyphStyle1.color = Color.YELLOW;
				glyphStyle1.width = font.config.width * 1.0;
				glyphStyle1.height = font.config.height * 1.0;
				//glyphStyle1.zIndex = 1;
				//glyphStyle1.rotation = 22.5;
								
				
				// -----------

				var glyph1 = fontProgram.createGlyph("A".charCodeAt(0), 0, 50, glyphStyle1);
				
				//fontProgram.glyphSetChar(glyph1, "x".charCodeAt(0));
				//glyph1.color = Color.BLUE;
				//glyph1.width = font.config.width * 2;
				//glyph1.height = font.config.height * 2;
				//fontProgram.updateGlyph(glyph1);
				//fontProgram.removeGlyph( glyph1 );
				
				// -----------
				
				//var glyphStyle2 = new GlyphStyle();
				var glyphStyle2 = font.createFontStyle();
				glyphStyle2.color = Color.RED;
				glyphStyle2.width = font.config.width * 2.0;
				glyphStyle2.height = font.config.height * 2.0;
				
				//fontProgram.setFontStyle(glyphStyle2);
				
				//var glyph2 = new Glyph<GlyphStyle>();
				var glyph2 = font.createGlyph();
				
				
				if (fontProgram.setGlyph( glyph2, "B".charCodeAt(0), 30, 50, glyphStyle1)) {
					Timer.delay(function() {
						fontProgram.glyphSetStyle(glyph2, glyphStyle2);
						fontProgram.updateGlyph(glyph2);
						Timer.delay(function() {
							fontProgram.removeGlyph(glyph2);
							Timer.delay(function() {
								fontProgram.addGlyph(glyph2);
							}, 1000);
						}, 1000);
					}, 1000);
				}
				else trace(" ----> Charcode not inside Font");
				
				
			},
			true // debug
			);

			
			
			
			timer = new Timer(40); zoomIn();
			
		} catch (e:Dynamic) trace("ERROR:", e);
	}

	// ---------------------------------------------------------------
	
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