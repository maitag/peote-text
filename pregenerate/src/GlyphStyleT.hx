package;

// @multiSlot    // multiple slots per texture to store multiple unicode-ranges
// @multiTexture // multiple textures to store multiple unicode-ranges

class GlyphStyleT
{

	//@global public var color:Int = 0x43cb18ff;
	public var color:Int = 0x43cb18ff;
	
	//@global public var bgColor:Int = 0;
	//public var bgColor:Int = 0;
	
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
	
	
	// ----- TODO ------
	//@global public var weight = 0.48;  for distance field fonts
	public var weight:Float = 0.5; // for distance field fonts
	
	// adjusting Glyphes inside Line
	// public var letterSpace:Float = 2.0;
	
	// outline/glow for distance field fonts
	
	public function new() {}
}