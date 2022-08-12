package peote.text.skin;

import peote.view.Display;
import peote.view.Mask;
import peote.view.Program;

interface SkinProgram
{
	public var useMaskIfAvail(default, null):Bool;
	public var depthIndex(default, null):Int;
	
	public function addElement(skinElement:SkinElement):SkinElement;
	public function updateElement(skinElement:SkinElement):Void;
	
	// from Program base-class
	var mask:Mask;
	
	public function addToDisplay(display:Display, ?atProgram:Program, addBefore:Bool = false):Void;
	public function removeFromDisplay(display:Display):Void;
}