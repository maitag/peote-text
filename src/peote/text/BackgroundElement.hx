package peote.text;

import peote.view.Color;
import peote.view.Element;

class BackgroundElement implements Element
{
	@posX public var x:Float;
	@posY public var y:Float;
	
	@sizeX public var w:Float;
	@sizeY public var h:Float;
	
	@zIndex public var z:Int;

	@color public var color:Color;

	public function new(x:Float, y:Float, w:Float, h:Float, z:Int, color:Color)
	{
		update(x, y, w, h, z, color);
	}
	
	public inline function update(x:Float, y:Float, w:Float, h:Float, z:Int, color:Color)
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.z = z;
		this.color = color;
	}
	
}