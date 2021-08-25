package;

import haxe.Timer;
import lime.utils.Bytes;
import haxe.CallStack;

import lime.app.Application;
import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;
import lime.graphics.Image;

import utils.Loader;

import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Buffer;
import peote.view.Program;
import peote.view.Color;
import peote.view.Texture;
import peote.view.utils.Util;
import peote.view.Element;

import peote.text.Gl3FontData;

#if isInt
class Elem implements Element { // signed 2 bytes integer
	@posX public var x:Int; 
	@posY public var y:Int;
	
	@sizeX public var w:Int;
	@sizeY public var h:Int;
	
	@texX public var tx:Int;
	@texY public var ty:Int;
	@texW public var tw:Int;
	@texH public var th:Int;
	
	@color("COL") public var c:Color;	
	public function new(positionX:Int=0, positionY:Int=0, c:Int=0xddddddff ) {
		this.x = positionX;
		this.y = positionY;
		this.c = c;
	}
}
#else
class Elem implements Element { // 4 bytes float
	@posX public var x:Float; 
	@posY public var y:Float;
	
	@sizeX public var w:Float;
	@sizeY public var h:Float;
	
	@texX public var tx:Float;
	@texY public var ty:Float;
	@texW public var tw:Float;
	@texH public var th:Float;

	@color("COL") public var c:Color;
	public function new(positionX:Float=0, positionY:Float=0, c:Int=0xddddddff ) {
		this.x = positionX;
		this.y = positionY;
		this.c = c;
	}
}
#end

class Gl3FontRendering extends Application
{
	var peoteView:PeoteView;
	var element:Elem;
	var buffer:Buffer<Elem>;
	var display:Display;
	var program:Program;
	var texture:Texture;
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
		peoteView.addDisplay(display);  // display to peoteView
		
		buffer  = new Buffer<Elem>(10000);
		program = new Program(buffer);
		
		
		// no kerning (much faster then to convert fontdata!) for the u n i glyphes
		//loadFont("assets/fonts/packed/DejavuSans", 0x0000, 0x0fff, true,
		loadFont("assets/fonts/packed/unifont/unifont_0000-0fff", 0x0000, 0x0fff, false,
		//loadFont("assets/fonts/packed/unifont/unifont_1000-1fff", 0x1000, 0x1fff, false,
		//loadFont("assets/fonts/packed/unifont/unifont_3000-3fff", 0x3000, 0x3fff, false,
			function(gl3font:Gl3FontData, image:Image, isKerning:Bool)
			{
				var texture = new Texture(image.width, image.height, 1, 4, false, 1, 1);
				texture.setImage(image);
				program.setTexture(texture, "TEX");
				display.addProgram(program);    // programm to display
				
				var bold = Util.toFloatString(0.5);
				var sharp = Util.toFloatString(0.5);
				
				program.setColorFormula('COL * smoothstep( $bold - $sharp * fwidth(TEX.r), $bold + $sharp * fwidth(TEX.r), TEX.r)');
				//program.setColorFormula('vec4(COL.rgb,  smoothstep( $bold - $sharp * fwidth(TEX.r), $bold + $sharp * fwidth(TEX.r), TEX.r) )');
				//program.setColorFormula('vec4(COL.rgb,  smoothstep( 0.5 - fwidth(TEX.r), 0.5 + fwidth(TEX.r), TEX.r) )');
				//program.alphaEnabled = true;
				//program.discardAtAlpha( 0.0 );
				
				// for unifont + INT is this best readable (but good not scalable and not not for all letters!!!) at fixed scale 16 ( or 32.. etc)
				//program.setColorFormula('COL * smoothstep( 0.5, 0.5, TEX.r)');
				
				renderTextLine(	100, 4, 24, gl3font, image.width, image.height, isKerning,
					"Unifont Test with peote-view and gl3font"
				);
				renderTextLine(	100, 30, 24, gl3font, image.width, image.height, isKerning,
					" -> move the display with cursorkeys (more speed with shift)"
				);
				renderTextLine(	100, 50, 24, gl3font, image.width, image.height, isKerning,
					" -> zoom the display with numpad +- (shift is zooming the view)"
				);
				
				var i:Int = 0;
				var l:Int = 90;
				var c:Int = 0;
				var s = new haxe.Utf8();
				
				for (charcode in gl3font.rangeMin...gl3font.rangeMax+1)
				{
					if (gl3font.getMetric(charcode) != null) 
					{
						s.addChar( charcode );
						i++; c++;
						if (i > 100) {
							//trace("charnumber:",c,"line:",l);
							renderTextLine( 30, l, 24, gl3font, image.width, image.height, isKerning, s.toString());
							i = 0; s = new haxe.Utf8(); l += 26;
						}
					}
				}
				
			}
		);
		
		
		timer = new Timer(40); zoomIn();
			
	}

	public function loadFont(font:String, rangeMin:Int, rangeMax:Int, isKerning:Bool, onLoad:Gl3FontData->Image->Bool->Void)
	{
		Loader.bytes(font+".dat", true, function(bytes:Bytes) {
			var gl3font = new Gl3FontData(bytes, rangeMin, rangeMax, isKerning);
			Loader.image(font+".png", true, function(image:Image) {
				onLoad(gl3font, image, isKerning);
			});
		});						
	}
	
	public function renderTextLine(x:Float, y:Float, scale:Float, gl3font:Gl3FontData, imgWidth:Int, imgHeight:Int, isKerning:Bool, text:String)
	{
		var penX:Float = x;
		var penY:Float = y;
		
		var prev_metric:Metric = null;
		
		peote.text.util.StringUtils.iter(text, function(charcode)
		{
			//trace("charcode", charcode);
			var metric:Metric = gl3font.getMetric(charcode);
			
			//if (id != null)
			if (metric != null)
			{
				#if isInt
				if (isKerning && prev_metric != null) { // KERNING
					penX += Math.ceil(gl3font.kerning[prev_metric.kerning][metric.kerning] * scale);
					//trace("kerning to left letter: " + Math.round(gl3font.kerning[prev_metric.kerning][metric.kerning] * scale) );
				}
				prev_metric = metric;
				
				//trace(charcode, "h:"+metric.height, "t:"+metric.top );
				element  = new Elem(
					Math.floor((penX + metric.left * scale )),
					Math.floor((penY + ( gl3font.height - metric.top ) * scale ))
				);
				
				penX += Math.ceil(metric.advance * scale);

				element.w  = Math.ceil( metric.width  * scale );
				element.h  = Math.ceil( metric.height * scale );
				element.tx = Math.floor(metric.u * imgWidth );
				element.ty = Math.floor(metric.v * imgHeight);
				element.tw = Math.floor(1+metric.w * imgWidth );
				element.th = Math.floor(1+metric.h * imgHeight);
				#else
				if (isKerning && prev_metric != null) { // KERNING
					penX += gl3font.kerning[prev_metric.kerning][metric.kerning] * scale;
					//trace("kerning to left letter: " + Math.round(gl3font.kerning[prev_metric.kerning][metric.kerning] * scale) );
				}
				prev_metric = metric;
				
				//trace(charcode, "h:"+metric.height, "t:"+metric.top );
				element  = new Elem(
					penX + metric.left * scale,
					penY + ( gl3font.height - metric.top ) * scale
				);
				
				penX += metric.advance * scale;

				element.w  = metric.width  * scale;
				element.h  = metric.height * scale;
				element.tx = metric.u * imgWidth;
				element.ty = metric.v * imgHeight;
				element.tw = metric.w * imgWidth;
				element.th = metric.h * imgHeight;
				#end
				buffer.addElement(element);     // element to buffer
			}
		});
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