package peote.text.skin.simple;

import peote.view.Buffer;
import peote.view.Program;

import peote.text.skin.SkinProgram;
import peote.text.skin.SkinElement;

class SimpleSkinProgram extends Program implements SkinProgram 
{
	var _buffer:Buffer<SimpleSkinElement>;
	public var useMaskIfAvail(default, null):Bool = true;
	public var depthIndex(default, null):Int = -1;
	
	public function new() 
	{
		_buffer = new Buffer<SimpleSkinElement>(16, 16, true);
		super(_buffer);
	}
	
	// -------- SkinProgram - Interface ----------
	public inline function addElement(skinElement:SkinElement):SkinElement {
		_buffer.addElement(cast (skinElement, SimpleSkinElement));
		return skinElement;
	}
	
	public inline function updateElement(skinElement:SkinElement):Void {
		_buffer.updateElement(cast skinElement);
	}
	
}