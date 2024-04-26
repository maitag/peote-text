# Peote Text - Glyph and Textrendering for [peote-view](https://github.com/maitag/peote-view)


## Installation:
```
haxelib git peote-text https://github.com/maitag/peote-text
```

## FontProgram

### Glyph

- createGlyph(charcode:Int, x:Float, y:Float, ?glyphStyle:MyStyle, useMetric = false):Glyph<MyStyle>
- createGlyphAtBase(charcode:Int, x:Float, y:Float, ?glyphStyle:MyStyle):Glyph<MyStyle>

- glyphAdd(glyph:Glyph<MyStyle>)
- glyphRemove(glyph:Glyph<MyStyle>)

- glyphSet(glyph:Glyph<MyStyle>, charcode:Int, x:Float, y:Float, ?glyphStyle:MyStyle, useMetric = false):Bool
- glyphSetAtBase(glyph:Glyph<MyStyle>, charcode:Int, x:Float, y:Float, ?glyphStyle:MyStyle):Bool

- glyphSetChar(glyph:Glyph<MyStyle>, charcode:Int, useMetric:Bool = false)

- glyphSetStyle(glyph:Glyph<MyStyle>, glyphStyle:MyStyle, useMetric = false)

- glyphSetPosition(glyph:Glyph<MyStyle>, x:Float, y:Float, useMetric = false)
- glyphSetPositionAtBase(glyph:Glyph<MyStyle>, x:Float, y:Float)

- glyphSetXPosition(glyph:Glyph<MyStyle>, x:Float, useMetric = false)
- glyphGetXPosition(glyph:Glyph<MyStyle>, useMetric = false)

- glyphSetYPosition(glyph:Glyph<MyStyle>, y:Float, useMetric = false)
- glyphSetYPositionAtBase(glyph:Glyph<MyStyle>, y:Float)

- glyphGetYPosition(glyph:Glyph<MyStyle>, useMetric = false):Float
- glyphGetYPositionAtBase(glyph:Glyph<MyStyle>):Float

- glyphGetBaseline(glyph:Glyph<MyStyle>):Float

- glyphUpdate(glyph:Glyph<MyStyle>)


- updateAllGlyphes()

- numberOfGlyphes():Int



### PageLine

- createPageLine(chars:String, x:Float = 0.0, y:Float = 0.0, ?size:Null<Float>, ?offset:Null<Float>, ?glyphStyle:Null<MyStyle>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):PageLine<MyStyle>

- pageLineAdd            (pageLine:PageLine<MyStyle>)
- pageLineRemove         (pageLine:PageLine<MyStyle>)

- pageLineSet            (pageLine:PageLine<MyStyle>, chars:String, x:Float, ?y:Null<Float>, size:Float, offset:Float, ?glyphStyle:Null<MyStyle>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void)

- pageLineSetStyle       (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, glyphStyle:MyStyle, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):Float

- pageLineSetPosition    (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, xNew:Float, yNew:Float, ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
- pageLineSetXPosition   (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, xNew:Float,             ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
- pageLineSetYPosition   (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, yNew:Float,             ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
- pageLineSetPositionSize(pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, xNew:Float, yNew:Float, ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
- pageLineSetSize        (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float,                         ?offsetNew:Null<Float>, addRemoveGlyphes:Bool = true)
- pageLineSetOffset      (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float,                          offsetNew:Float,       addRemoveGlyphes:Bool = true)

- pageLineSetChar        (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, charcode:Int, position:Int = 0, ?glyphStyle:MyStyle, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
- pageLineSetChars       (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, chars:String, position:Int = 0, ?glyphStyle:MyStyle, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
//TODO: pageLineReplaceChars(pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, chars:String, from:Int, to:Int, ...)

- pageLineInsertChar     (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, charcode:Int, position:Int = 0, ?glyphStyle:MyStyle, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
- pageLineInsertChars    (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, chars:String, position:Int = 0, ?glyphStyle:MyStyle, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float 

- pageLineAppendChars    (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, chars:String,                   ?glyphStyle:MyStyle, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float 

- pageLineDeleteChar     (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, position:Int = 0           , addRemoveGlyphes:Bool = true):Float
- pageLineDeleteChars    (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):Float

- pageLineCutChars       (pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):String
- pageLineGetChars       (pageLine:PageLine<MyStyle>                                   , from:Int = 0, ?to:Null<Int>):String


- pageLineUpdate(pageLine:PageLine<MyStyle>, ?from:Null<Int>, ?to:Null<Int>)

- pageLineGetPositionAtChar(pageLine:PageLine<MyStyle>, x:Float,             offset:Float, position:Int):Float
- pageLineGetCharAtPosition(pageLine:PageLine<MyStyle>, x:Float, size:Float, offset:Float, xPosition:Float):Int



### Line

- createLine(chars:String, x:Float, y:Float, ?size:Null<Float>, ?offset:Null<Float>, ?glyphStyle:Null<MyStyle>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Line<MyStyle>

- lineAdd     (line:Line<MyStyle>)
- lineRemove  (line:Line<MyStyle>)

- lineSet     (line:Line<MyStyle>, chars:String, ?x:Null<Float>, ?y:Null<Float>, ?size:Null<Float>, ?offset:Null<Float>, ?glyphStyle:Null<$styleType>, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void)

- lineSetStyle   (line:Line<MyStyle>, glyphStyle:$styleType, from:Int = 0, ?to:Null<Int>, addRemoveGlyphes:Bool = true):Float

- lineSetPosition    (line:Line<MyStyle>, x:Float, y:Float,             ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
- lineSetXPosition   (line:Line<MyStyle>, x:Float,                      ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
- lineSetYPosition   (line:Line<MyStyle>, y:Float,                      ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
- lineSetPositionSize(line:Line<MyStyle>, x:Float, y:Float, size:Float, ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
- lineSetSize        (line:Line<MyStyle>,                   size:Float, ?offset:Null<Float>, addRemoveGlyphes:Bool = true)
- lineSetOffset      (line:Line<MyStyle>,                                offset:Float,       addRemoveGlyphes:Bool = true)

- lineSetChar        (line:Line<MyStyle>, charcode:Int, position:Int = 0, ?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
- lineSetChars       (line:Line<MyStyle>, chars:String, position:Int = 0, ?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
//TODO: lineReplaceChars(line:Line<MyStyle>, chars:String, from:Int, to:Int, ...)

- lineInsertChar     (line:Line<MyStyle>, charcode:Int, position:Int = 0, ?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
- lineInsertChars    (line:Line<MyStyle>, chars:String, position:Int = 0, ?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float
- lineAppendChars    (line:Line<MyStyle>, chars:String,                   ?glyphStyle:$styleType, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Void):Float

- lineDeleteChar     (line:Line<MyStyle>, position:Int = 0,                                       addRemoveGlyphes:Bool = true):Float
- lineDeleteChars    (line:Line<MyStyle>, from:Int = 0, ?to:Null<Int>,                            addRemoveGlyphes:Bool = true):Float

- lineCutChars       (line:Line<MyStyle>, from:Int = 0, ?to:Null<Int>,                            addRemoveGlyphes:Bool = true):String
- lineGetChars       (line:Line<MyStyle>, from:Int = 0, ?to:Null<Int>):String

- lineUpdate         (line:Line<MyStyle>, ?from:Null<Int>, ?to:Null<Int>)

- lineGetPositionAtChar(line:Line<MyStyle>, position:Int):Float
- lineGetCharAtPosition(line:Line<MyStyle>, xPosition:Float):Int


### Page

- createPage(chars:String, x:Float, y:Float, ?width:Null<Float>, ?height:Null<Float>, ?xOffset:Null<Float>, ?yOffset:Null<Float>, glyphStyle:Null<$styleType> = null, ?onUnrecognizedChar:Int->Int->Int->Void):peote.text.Page<$styleType>

- pageAdd(page:Page<$styleType>)
- pageRemove(page:Page<$styleType>)

- pageSet(page:Page<$styleType>, chars:String, ?x:Null<Float>, ?y:Null<Float>, ?width:Null<Float>, ?height:Null<Float>, ?xOffset:Null<Float>, ?yOffset:Null<Float>,
		?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Int->Void)
		
- pageAppendChars(page:Page<$styleType>, chars:String, ?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Int->Void):Float
- pageSetStyle(page:Page<$styleType>, glyphStyle:$styleType, fromLine:Int = 0, fromPosition:Int = 0, ?toLine:Null<Int>, ?toPosition:Null<Int>, addRemoveGlyphes:Bool = true):Float
- pageInsertChars(page:Page<$styleType>, chars:String, lineNumber:Int = 0, position:Int = 0
                  ?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true, ?onUnrecognizedChar:Int->Int->Int->Void)

- pageTextWidthAfterExpand(page:Page<$styleType>, pageLine:PageLine<$styleType>)
- pageIsLongestLine(page:Page<$styleType>, pageLine:PageLine<$styleType>):Bool
- pageTextWidthAfterShrink(page:Page<$styleType>, pageLine:PageLine<$styleType>)
- pageTextWidthAfterDelete(page:Page<$styleType>)

- ----- TODO: ------
- pageGetChars    (page:Page<$styleType>, fromLine:Int = 0, fromChar:Int = 0, ?toLine:Null<Int>, ?toChar:Null<Int>):String
- pageCutChars    (page:Page<$styleType>, fromLine:Int = 0, fromChar:Int = 0, ?toLine:Null<Int>, ?toChar:Null<Int>):String

- pageDeleteChars (page:Page<$styleType>, fromLine:Int, toLine:Int, fromChar:Int, toChar:Int, addRemoveGlyphes:Bool = true)

- pageSetChars    (page:Page<$styleType>, chars:String, fromLine:Int = 0, fromChar:Int = 0, ?toLine:Null<Int>, ?toChar:Null<Int>)
- pageReplaceChars(page:Page<$styleType>, chars:String, fromLine:Int = 0, fromChar:Int = 0, ?toLine:Null<Int>, ?toChar:Null<Int>)

- pageAddLinefeed   (page:Page<$styleType>, lineNumber:Int, ?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true)
- pageNewLinefeed   (page:Page<$styleType>, lineNumber:Int, afterLine:Bool = true, ?glyphStyle:$styleType, ?defaultFontRange:Null<Int>, addRemoveGlyphes:Bool = true)
- pageRemoveLinefeed(page:Page<$styleType>, lineNumber:Int, addRemoveGlyphes:Bool = true)

- pageDeleteLine(page:Page<$styleType>, lineNumber:Int)
- pageDeleteLines(page:Page<$styleType>, fromLineNumber:Int, toLineNumber:Int)

- pageCutLine
- pageCopyLine


// maybe better only setLineMetric() here ?
public function pageSetLineSpace(page:Page<$styleType>, lineSpace:Float, fromLine:Int = 0, toLine:Null<Int> = null, addRemoveGlyphes:Bool = true)
--------------------

- pageSetPosition(page:Page<$styleType>, x:Float, y:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true)
- pageSetXPosition(page:Page<$styleType>, x:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true) 
- pageSetYPosition(page:Page<$styleType>, y:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true)
- pageSetPositionSize(page:Page<$styleType>, x:Float, y:Float, width:Float, height:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true)
- pageSetSize(page:Page<$styleType>, width:Float, height:Float, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true)
- pageSetOffset(page:Page<$styleType>, ?xOffset:Null<Float>, ?yOffset:Null<Float>, addRemoveGlyphes:Bool = true)
- pageSetXOffset(page:Page<$styleType>, xOffset:Float, addRemoveGlyphes:Bool = true)
- pageSetYOffset(page:Page<$styleType>, yOffset:Float, addRemoveGlyphes:Bool = true)

- pageUpdate(page:Page<$styleType>, from:Null<Int> = null, to:Null<Int> = null)


- pageGetPositionAtChar(page:Page<$styleType>, pageLine:PageLine<$styleType>, position:Int):Float
- pageGetCharAtPosition(page:Page<$styleType>, pageLine:PageLine<$styleType>, xPosition:Float, intoVisibleRange:Bool = true):Int

- pageGetLineAtPosition(page:Page<$styleType>, yPosition:Float):PageLine<MyStyle>
- pageGetLineAtPosition(page:Page<$styleType>, yPosition:Float, intoVisibleRange:Bool = true):Int


-----------------------------------------------------



