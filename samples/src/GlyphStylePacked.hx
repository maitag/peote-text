package;

import peote.view.Color;

// @multiSlot    // multiple slots per texture to store multiple unicode-ranges
// @multiTexture // multiple textures to store multiple unicode-ranges
// @useInt // TODO
@packed  // glyphes are packed into textureatlas with ttfcompile (gl3font)
class GlyphStylePacked 
{
	//@global public var color:Color = Color.GREEN;
	public var color:Color = Color.GREEN;
	
	//@global public var bgColor:Color = Color.BLUE;
	//public var bgColor:Color = 0;
	
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
	//public var letterSpace:Float = 5.0;
	
	// outline/glow for distance field fonts
	
	public function new() {}
}