package peote.text;

import peote.view.Element;


class MaskElement implements Element
{
	@posX public var x:Int=0; // signed 2 bytes integer
	@posY public var y:Int=0; // signed 2 bytes integer
	
	@sizeX public var w:Int=0;
	@sizeY public var h:Int=0;

	public function new(x:Int, y:Int, w:Int, h:Int)
	{
		update(x, y, w, h);
	}
	
	public inline function update(x:Int, y:Int, w:Int, h:Int)
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
	
}