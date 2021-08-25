package peote.text.util;

class StringUtils 
{
	static public inline function iter(chars:String, f:Int->Void):Void
	{
		#if (haxe_ver >= "4.0.0")
			#if (neko)
			for (charcode in haxe.iterators.StringIteratorUnicode.unicodeIterator(chars)) f(charcode);
			#else
			for (charcode in StringTools.iterator(chars)) f(charcode);
			#end
		#else
		haxe.Utf8.iter(chars, f);
		#end		
	}
	
}