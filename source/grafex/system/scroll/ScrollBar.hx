package grafex.system.scroll;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;
import flixel.FlxG;

class ScrollBar extends FlxTypedGroup
{
    var x:Float = 0;
    var y:Float = 0;
    
    var width:Int;
    var height:Int;
    
    var bg:FlxSprite;
    var dfjk:FlxSprite;

    var mouseEvent:FlxMouseEventManager;

    var dfjkOffset:FlxPoint;
    var dragging:Bool = false;

    var 

    public function new(x:Float = 0, y:Float = 0, width:Int, height:Int)
    {
        super();

        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;

        mouseEvent = new FlxMouseEventManager();
        add(mouseEvent);

        dfjkOffset = new FlxPoint();

        bg = new FlxSprite(x, y).makeGraphic(width, height, FlxColor.BLACK);
        bg.alpha = 0.4;
        add(bg);

        dfjk = new FlxSprite(x, y).makeGraphic(width, width * 2, FlxColor.WHITE);
        dfjk.alpha = 0.2;
        add(dfjk);
        mouseEvent.add(dfjk, pressDFJK, releaseDFJK, null, null);
    }

    function pressDFJK(object:FlxObject)
    {
        dfjkOffset.set(FlxG.mouse.x - dfjk.x, FlxG.mouse.y - dfjk.y);
        dragging = true;
    }

    function releaseDFJK(object:FlxObject)
    {
        dfjkOffset.set(0, 0);
        dragging = false;
    }

    override function update(elapsed:Float)
    {
        if (dragging)
        {
            if (dfjk.y < (bg.x + bg.height) - dfjk.height && dfjk.y > bg.y)
            {
                dfjk.y = FlxG.mouse.y - dfjkOffset.y;
            }
        }

        if (dfjk.y >= (bg.x + bg.height) - dfjk.height)
        {
            dfjk.y = (bg.x + bg.height) - dfjk.height - 1;
        }
        if (dfjk.y <= bg.y)
        {
            dfjk.y = bg.y + 1;
        }
    }
}