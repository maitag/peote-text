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

import peote.text.Font;

import peote.text.FontProgram;
import peote.text.Line;
import peote.text.MaskElement;
import peote.text.BackgroundElement;


//@multiSlot    // multiple slots per texture to store multiple unicode-ranges
//@multiTexture // multiple textures to store multiple unicode-ranges
// TODO:
//@maskX @maskY // cutting the first and last glyph into line if it is outside of offset and max
//@useInt       // using Integer for all glyphpositions and -sizes
#if packed
@packed        // glyphes are packed into textureatlas with ttfcompile (gl3font)
#end
class GlyphStyle {
	//@global public var color:Color = Color.GREEN;
	public var color:Color = Color.GREEN;
	
	//@global public var bgColor:Color = Color.BLUE;
	//public var bgColor:Color = Color.BLUE;
	
	//@global public var width:Float = 10.0;
	public var width:Float = 16;
	//@global public var height:Float = 16.0;
	public var height:Float = 16;
	
	//public var zIndex:Int = -1;
	
	//@global public var tilt:Float = 0.5;
	//public var tilt:Float = 0.0;
	
	//@global public var weight = 0.48;
	//public var weight:Float = 0.48;
	
	// additional spacing after each letter
	@global public var letterSpace:Float = 5.0;
	//public var letterSpace:Float = 10.0;
	
	// TODO: outline/glow for distance field fonts
	
	public function new() {}
}

#if html5
@:access(lime._internal.backend.html5.HTML5Window)
#end
class InputLine extends Application
{
	var peoteView:PeoteView;
	var display:Display;
	var timer:Timer;
	
	var helperElems:{bg:BackgroundElement,top:BackgroundElement,base:BackgroundElement,desc:BackgroundElement};
	
	var fontProgram:FontProgram<GlyphStyle>;
	
	var line:Line<GlyphStyle>;
	var line_x:Float = 10;
	var line_offset:Float = 0;
	var line_y:Float = 100;
	
	var mask:MaskElement;
	
	var actual_style:Int = 0;
	var glyphStyle = new Array<GlyphStyle>();
		
	var cursor:Int = 0;
	var cursorElem:BackgroundElement;
	var cursor_x:Float = 0;
	
	var selectElem:BackgroundElement;
	var select_x:Float = 0;
	var select_from:Int = 0;
	var select_to:Int = 0;
	var hasSelection(get, set):Bool;
	inline function get_hasSelection():Bool return (select_from != select_to);
	inline function set_hasSelection(has:Bool) {
		if (!has) select_to = select_from;
		return has;
	}
		
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
		window.textInputEnabled = true; // this is disabled on default for html5

		peoteView = new PeoteView(window);
		display   = new Display(10, 10, window.width - 20, window.height - 20, Color.GREY1);
		#if mobile
		display.zoom = 3.0;
		#end
		peoteView.addDisplay(display);
		
		#if packed
		new Font<GlyphStyle>("assets/fonts/packed/hack/config.json")
		//new Font<GlyphStyle>("assets/fonts/packed/unifont/config.json", [new peote.text.Range(0x0000,0x0fff)])
		//new Font<GlyphStyle>("assets/fonts/packed/unifont/config.json")
		//new Font<GlyphStyle>("assets/fonts/packed/unifont/config.json", [peote.text.Range.C0ControlsBasicLatin(), peote.text.Range.C1ControlsLatin1Supplement()])
		#else
		new Font<GlyphStyle>("assets/fonts/tiled/hack_ascii.json")
		//new Font<GlyphStyle>("assets/fonts/tiled/liberation_ascii.json")
		//new Font<GlyphStyle>("assets/fonts/tiled/peote.json")
		#end
		.load( function(font) {
		
			var fontStyle = new GlyphStyle();
			
			//fontProgram = new FontProgram<GlyphStyle>(font, fontStyle, true); // manage the Programs to render glyphes in different size/colors/fonts
			// alternative way to create the FontProgram<GlyphStyle>:
			fontProgram = font.createFontProgram(fontStyle, true, true);
			//fontProgram.snapToPixel(1.0);
			
			display.addProgram(fontProgram);
			
			// ------------------- Styles  -------------------				
			var style:GlyphStyle;
			
			style = new GlyphStyle();
			style.width = font.config.width;
			style.height = font.config.height;
			glyphStyle.push(style);
			
			style = new GlyphStyle();
			style.color = Color.YELLOW;
			style.width = font.config.width * 2.0;
			style.height = font.config.height * 2.0;
			glyphStyle.push(style);
			
			style = new GlyphStyle();
			style.color = Color.RED;
			style.width = font.config.width * 3.0;
			style.height = font.config.height * 3.0;
			glyphStyle.push(style);				
			
			// ------------------- line  -------------------				
			line = new Line<GlyphStyle>();
			
			setLine("Testing input textline and masking. (page up/down is toggling glyphstyle)", window.width - 20 - line_x * 2, line_offset);
			

			trace("font height "+font.config.height+"");
			trace("base "+line.base+" (font baseline)");
			trace("lineHeight "+line.lineHeight);
			trace("height "+line.height+" (heighest glyph)" );
			trace("textSize "+line.textSize);
			trace("length "+line.length+" (number of glyphes)" );

			mask = fontProgram.createMask(Std.int(line.x), Std.int(line.y)-40, Std.int(line.size), Std.int(line.lineHeight)+80);
			
			// -------- background and helperlines ---------				
			createHelperLines(line.size, line.lineHeight);
			
			// ----------------- Cursor  -------------------	
			cursor_x = line_x;
			cursorElem = fontProgram.createBackground(line_x, line_y, 1, line.height, 1, Color.RED);
			
			// --------------- Selection  -------------------				
			selectElem = fontProgram.createBackground(line_x, line_y, 0, line.lineHeight, 0, Color.GREY3);
			
				
			//fontProgram.lineSetChar(line, "A".charCodeAt(0) , 0, glyphStyle2);
			
			//fontProgram.lineSetPosition(line, line.x+10, line.y+10);
			
			window.onResize.add(onResize);
		});
	}
	
	// ---------------------------------------------------------------

	public function setLine(s:String, size:Float, offset:Float)
	{
		fontProgram.setLine(line, s, line_x, line_y, size, offset, glyphStyle[actual_style]);
	}
	
	public function lineInsertChar(charcode:Int)
	{
		if (hasSelection) lineDeleteChars(select_from, select_to);
		var offset = fontProgram.lineInsertChar(line, charcode, cursor, glyphStyle[actual_style]);
		if ( offset != 0) {
			if (cursor == 0) moveCursor(fontProgram.lineGetPositionAtChar(line, cursor+1) - cursorElem.x);
			else moveCursor(offset);
			lineUpdate();
			cursor ++;
		}
	}
	
	public function lineInsertChars(text:String)
	{
		if (hasSelection) lineDeleteChars(select_from, select_to);
		var old_length = line.length;
		var offset = fontProgram.lineInsertChars(line, text, cursor, glyphStyle[actual_style]);
		if ( offset != 0) {
			if (cursor == 0) moveCursor(fontProgram.lineGetPositionAtChar(line, cursor + line.length - old_length) - cursorElem.x);
			else moveCursor(offset);
			lineUpdate();
			cursor += line.length - old_length;
		}
	}
	
	public function lineDeleteChar(isCtrl:Bool)
	{
		if (hasSelection) {
			lineDeleteChars(select_from, select_to);
		}
		else if (cursor < line.length) {
			if (isCtrl) {
				var to = cursor;
				if (line.getGlyph(to).char != 32) do to++ while (to < line.length && line.getGlyph(to).char != 32);
				do to++ while (to < line.length && line.getGlyph(to).char == 32);
				lineDeleteChars(cursor, to);
			}
			else {
				fontProgram.lineDeleteChar(line, cursor);
				lineUpdate();
				if (cursor == line.length) cursorSet(line.length);
			}
		}
	}
	
	public function lineDeleteCharBack(isCtrl:Bool)
	{
		if (hasSelection) {
			lineDeleteChars(select_from, select_to);
		}
		else if (cursor > 0) {
			if (isCtrl) {
				var from = cursor;
				do cursor-- while (cursor > 0 && line.getGlyph(cursor).char == 32);
				while (cursor > 0 && line.getGlyph(cursor-1).char != 32) cursor--;
				lineDeleteChars(from, cursor);
			}
			else {
				cursor--;
				moveCursor(fontProgram.lineDeleteChar(line, cursor));
				lineUpdate();
			}
		}
	}
	
	function lineDeleteChars(from:Int, to:Int)
	{
		if (to < from) {var tmp = to; to = from; from = tmp; }
		fontProgram.lineDeleteChars(line, from, to);
		lineUpdate();
		selectionSetFrom(from);
		selectionSetTo(from);
		cursorSet(from);
	}
	
	public function lineCutChars():String
	{
		var cut = "";
		if (hasSelection) {
			var from = select_from;
			var to = select_to;
			if (to < from) {to = select_from; from = select_to; }
			cut = fontProgram.lineCutChars(line, from, to);
			lineUpdate();
			selectionSetTo(select_from);
			cursorSet(from);
		}
		return cut;
	}
	
	public function lineCopyChars():String
	{
		var copy = "";
		if (hasSelection) {
			var from = select_from;
			var to = select_to;
			if (to < from) {to = select_from; from = select_to; }
			for (i in ((from < line.visibleFrom) ? line.visibleFrom : from)...((to < line.visibleTo) ? to : line.visibleTo)) {
				copy += String.fromCharCode(line.getGlyph(i).char);
			}
		}
		return copy;		
	}
	
	public function lineChangeStyle()
	{
		if (hasSelection) {
			var from = select_from;
			var to = select_to;
			if (to < from) {to = select_from; from = select_to; }
			fontProgram.lineSetStyle(line, glyphStyle[actual_style], from, to);
			lineUpdate();
			selectionSetFrom(select_from);
			selectionSetTo(select_to);
			cursorSet(cursor);
		}
	}
	
	public function lineSetOffset(offset:Float)
	{
		fontProgram.lineSetOffset(line, line_offset + offset);
		lineUpdate();
		cursorElem.x = cursor_x + offset;
		fontProgram.updateBackground(cursorElem);
		selectElem.x = select_x + offset;
		fontProgram.updateBackground(selectElem);
	}
	
	public function lineUpdate()
	{
		fontProgram.updateLine(line);
		updateHelperLines(line_x, line.size, line.lineHeight);
	}
	
	public function moveCursor(offset:Float)
	{
		cursorElem.x += offset;
		if (cursorElem.x < line.x + line.offset) cursorElem.x = line.x + line.offset;
		fontProgram.updateBackground(cursorElem);
	}
	
	public function cursorRight(isShift:Bool, isCtrl:Bool)
	{
		if (hasSelection && !isShift) {
			if (select_from > select_to) cursorSet(select_from);
		}
		else if (cursor < line.length) {
			if (!hasSelection && isShift) selectionStart(cursor);
			if (isCtrl) {
				do cursor++ while (cursor < line.length && line.getGlyph(cursor).char != 32);
				while (cursor < line.length && line.getGlyph(cursor).char == 32) cursor++;
			}
			else cursor++;
			cursorElem.x = fontProgram.lineGetPositionAtChar(line, cursor);
			fontProgram.updateBackground(cursorElem);
			if (isShift) selectionSetTo(cursor);
		}
		if (!isShift) selectionSetTo(select_from);
	}
	
	public function cursorLeft(isShift:Bool, isCtrl:Bool)
	{
		if (hasSelection && !isShift) {
			if (select_from < select_to) cursorSet(select_from);
		}
		else if (cursor > 0) {
			if (!hasSelection && isShift) selectionStart(cursor);
			if (isCtrl) {
				do cursor-- while (cursor > 0 && line.getGlyph(cursor).char == 32);
				while (cursor > 0 && line.getGlyph(cursor-1).char != 32) cursor--;
			}
			else cursor--;
			cursorElem.x = fontProgram.lineGetPositionAtChar(line, cursor);
			fontProgram.updateBackground(cursorElem);
			if (isShift) selectionSetTo(cursor);
		}
		if (!isShift) selectionSetTo(select_from);
	}
	
	public function cursorSet(position:Int)
	{
		if (position >= 0 && position <= line.length) {
			cursor = position;
			cursorElem.x = fontProgram.lineGetPositionAtChar(line, cursor);
			fontProgram.updateBackground(cursorElem);
		}
	}
	
	public function selectionStart(from:Int)
	{
		if (from >= 0) {
			select_from = select_to = from;
			selectElem.x = fontProgram.lineGetPositionAtChar(line, from);
			selectElem.w = 0;
			fontProgram.updateBackground(selectElem);
		}
	}

	public function selectionSetFrom(from:Int)
	{
		if (from >= 0) {
			select_from = from;
			selectElem.x = fontProgram.lineGetPositionAtChar(line, from);
			fontProgram.updateBackground(selectElem);
		}
	}
	
	public function selectionSetTo(to:Int)
	{
		if (to <= line.length) {
			select_to = to;
			if (select_from == select_to) selectElem.w = 0;
			else selectElem.w = fontProgram.lineGetPositionAtChar(line, to) - selectElem.x;
			fontProgram.updateBackground(selectElem);
		}
	}
	
	// ---------------------------------------------------------------
	
	public function createHelperLines( width:Float, height:Float)
	{
		// bg
		var bg = fontProgram.createLineBackground(line, Color.GREY2);
		// top line
		var top = fontProgram.createBackground(Std.int(line.x), Std.int(line.y), Std.int(width), 1, 0, Color.GREY4);				
		// baseline
		var base = fontProgram.createBackground(Std.int(line.x), Std.int(line.y + line.base), Std.int(width), 1, 0, Color.GREY3);
		// descender line
		var desc = fontProgram.createBackground(Std.int(line.x), Std.int(line.y + height), Std.int(width), 1, 0, Color.GREY4);
		
		helperElems = {bg:bg, top:top, base:base, desc:desc};
	}
	
	public function updateHelperLines(x:Float, width:Float, height:Float)
	{
		helperElems.top.x = helperElems.base.x = helperElems.desc.x = x;
		helperElems.top.w = helperElems.base.w = helperElems.desc.w = width;
		
		fontProgram.setLineBackground(helperElems.bg, line);
		fontProgram.updateBackground(helperElems.top);
		fontProgram.updateBackground(helperElems.base);
		fontProgram.updateBackground(helperElems.desc);
	}

	// ---------------------------------------------------------------
	
	var selecting = false;
	var dragging = false;
	var dragX:Float = 0.0;
	override function onMouseDown (x:Float, y:Float, button:MouseButton):Void
	{	
		if ((y-display.y)/display.zoom > line.y && (y-display.y)/display.zoom < line.y + line.height) {
			cursorSet(fontProgram.lineGetCharAtPosition(line, (x - display.x) / display.zoom));
			selectionStart(cursor);
			selecting = true;
		}
		else {
			dragX = x;
			cursor_x = cursorElem.x;
			select_x = selectElem.x;
			dragging = true;
		}
	}
	
	override function onMouseUp (x:Float, y:Float, button:MouseButton):Void 
	{
		selecting = false;
		dragging = false;
		line_offset = line.offset;
		cursor_x = cursorElem.x;
		select_x = selectElem.x;
	}
	
	override function onMouseMove (x:Float, y:Float):Void
	{
		if (selecting) {
			cursorSet(fontProgram.lineGetCharAtPosition(line, (x - display.x) / display.zoom));
			selectionSetTo(cursor);
		}
		else if (dragging) {
			lineSetOffset((x - dragX)/display.zoom);
		}
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
			
			case KeyCode.PAGE_UP:
				actual_style = (actual_style+1) % glyphStyle.length;
				lineChangeStyle();
			case KeyCode.PAGE_DOWN:
				actual_style = (actual_style>0) ? actual_style-1 : glyphStyle.length-1;
				lineChangeStyle();

			case KeyCode.HOME: cursorSet(0);
			case KeyCode.END: cursorSet(line.length);

			// SELECT ALL
			case KeyCode.A: 
				if (modifier.ctrlKey || modifier.metaKey) {
					selectionSetFrom(0);
					selectionSetTo(line.length);
				}
				
			// CUT
			case KeyCode.X: 
				if (modifier.ctrlKey || modifier.metaKey) {
					lime.system.Clipboard.text = lineCutChars();
				}

			// COPY
			case KeyCode.C:
				if (modifier.ctrlKey || modifier.metaKey) {
					lime.system.Clipboard.text = lineCopyChars();
				}
				
			// PASTE
			case KeyCode.V: 
				if (modifier.ctrlKey || modifier.metaKey) {
					#if !html5
					if (lime.system.Clipboard.text != null) lineInsertChars(lime.system.Clipboard.text);
					#end
				}
			
			case KeyCode.DELETE: lineDeleteChar(modifier.ctrlKey || modifier.metaKey);
			case KeyCode.BACKSPACE: lineDeleteCharBack(modifier.ctrlKey || modifier.metaKey);
			case KeyCode.RIGHT: if (modifier.metaKey) cursorSet(line.length) else cursorRight(modifier.shiftKey, modifier.ctrlKey || modifier.altKey);
			case KeyCode.LEFT: if (modifier.metaKey) cursorSet(0) else cursorLeft(modifier.shiftKey, modifier.ctrlKey || modifier.altKey);
			default:
		}
	}
	
	override function onWindowActivate():Void 
	{
		#if html5
		//Timer.delay(function() {
			lime._internal.backend.html5.HTML5Window.textInput.focus();
		//}, 200);
		#end
	}
	
	override function onTextInput(text:String):Void 
	{
		//trace("onTextInput", text);
		
/*		haxe.Utf8.iter(text, function(charcode)
		{
			lineInsertChar(charcode);
		});
*/	
		lineInsertChars(text);
	}

	function onResize(width:Int, height:Int)
	{
		display.width  = width - 20;
		display.height = height - 20;
		fontProgram.lineSetSize(line, window.width - 20 - line_x * 2);
		cursor_x = cursorElem.x;
		select_x = selectElem.x;
		lineSetOffset(0);
		mask.update(Std.int(line.x), Std.int(line.y)-40, Std.int(line.size), Std.int(line.lineHeight)+80 );
		fontProgram.updateMask(mask);
	}

}