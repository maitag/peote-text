package peote.text;

import peote.view.Element;


class MaskElement implements Element
{
	@posX public var x:Int;
	@posY public var y:Int;
	
	@sizeX public var w:Int;
	@sizeY public var h:Int;

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