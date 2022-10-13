package peote.text.util;

class StringUtils 
{
	static public inline function iter(chars:String, f:Int->Void):Void
	{
		#if (haxe_ver >= "4.0.0")
			#if (neko)		
			// can be crash for wrong encoding:
			//for (charcode in haxe.iterators.StringIteratorUnicode.unicodeIterator(chars)) f(charcode);

/*			
			// This also did not really work cos substr() also wrong into encoding then
			var pos:Int = 0;
			var posNew:Int = 0;			
			var noMoreChars = false;
			do 
			{
				try {
					for (charcode in haxe.iterators.StringIteratorUnicode.unicodeIterator(chars))
					{
						f(charcode);
						posNew++;
					}
					noMoreChars = true;
				}
				catch (e) {
					pos += posNew;
					trace('neko charencoding problemchar "${chars.substr(posNew,1)}" at $pos:', chars.charCodeAt(posNew) );
					f(chars.charCodeAt(posNew));
					chars = chars.substr(posNew+1);
					pos++;
					posNew = 0;
					if (chars.length == 0) noMoreChars = true;
				}
			}
			while (!noMoreChars);
*/			
			var pos:Int = 0;
			try {
				for (charcode in haxe.iterators.StringIteratorUnicode.unicodeIterator(chars))
				{
					f(charcode);
					pos++;
				}
			}
			catch (e) {
				trace('WARNING: Neko charencoding problem at position $pos:');
				f(-1);
			}

			#else
			for (charcode in StringTools.iterator(chars)) f(charcode);
			#end
		#else
		haxe.Utf8.iter(chars, f);
		#end		
	}
	
}