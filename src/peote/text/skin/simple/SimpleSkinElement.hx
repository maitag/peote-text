package peote.text.skin.simple;

import peote.view.Element;
import peote.view.Color;

import peote.text.skin.SkinElement;

class SimpleSkinElement implements SkinElement implements Element
{
	@posX public var x:Float;
	@posY public var y:Float;
	
	@sizeX public var w:Float;
	@sizeY public var h:Float;
	
	@zIndex public var z:Int;

	@color public var color:Color;

	public inline function new(color:Color, x:Float=0, y:Float=0, w:Float=0, h:Float=0, z:Int=0)
	{
		update(x, y, w, h, z);
		this.color = color;
	}
	
	public inline function update(x:Float, y:Float, w:Float, h:Float, z:Int):Void
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.z = z;
	}
	
}