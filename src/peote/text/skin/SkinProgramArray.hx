package peote.text.skin;

import peote.view.Program;

@:forward
abstract SkinProgramArray(Array<SkinProgram>) 
{
	inline public function new() {
		this = new Array<SkinProgram>();
	}
	
	@:access(peote.view.Program, peote.text.skin)
	inline public function insertZSorted(skinProgram:SkinProgram, fontProgram:Program, depthIndex:Null<Int>, useMaskIfAvail:Null<Bool>) {
		
		if (depthIndex != null) skinProgram.depthIndex = depthIndex;
		
		var i:Int = 0;
		while (i < this.length) {
			if (skinProgram.depthIndex < this[i].depthIndex) break;
			else i++;
		}
		
		for (display in fontProgram.displays) {
			if (skinProgram.depthIndex < 0) {
				if (this.length == 0 || this.length == i || this[i].depthIndex > 0 ) skinProgram.addToDisplay(display, fontProgram, true);
				else skinProgram.addToDisplay(display, cast this[i], true);
			}
			else {
				if (this.length == 0 || this.length == i) skinProgram.addToDisplay(display, fontProgram);
				else skinProgram.addToDisplay(display, cast this[i], true);
			}
		}

		this.insert(i, skinProgram);
	}
}