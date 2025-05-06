package peote.text;

// @multiSlot    // multiple slots per texture to store multiple unicode-ranges
// @multiTexture // multiple textures to store multiple unicode-ranges
// @useInt // TODO
@packed  // glyphes are packed into textureatlas with ttfcompile (gl3font)
class GlyphStylePacked
{
	//@global
	public var color:peote.view.Color = peote.view.Color.GREEN;
	
	//@global
	//public var bgColor:peote.view.Color = 0;
	
	//@global
	public var width:Float = 16;
	
	//@global
	public var height:Float = 16;
	
	//@global
	//public var zIndex:Int = 0;
	
	//@global
	//public var rotation:Float = 0;
	
	//@global
	public var tilt:Float = 0.0;
	
	//@global
	public var weight:Float = 0.5; // for distance field fonts
	
	// adjusting Glyphes inside Line
	//@global
	public var letterSpace:Float = 0.0;
	
	public function new() {}
}