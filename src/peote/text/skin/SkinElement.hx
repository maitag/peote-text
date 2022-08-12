package peote.text.skin;

import peote.view.Color;

interface SkinElement 
{
	public var x:Float;
	public var y:Float;
	public var w:Float;
	public var h:Float;
	public var z:Int;
	
	public function update(x:Float, y:Float, w:Float, h:Float, z:Int):Void;
}