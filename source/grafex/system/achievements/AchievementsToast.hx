package grafex.system.achievements;

import grafex.sprites.attached.AttachedSprite;
import grafex.sprites.attached.AttachedText;

import flixel.util.FlxColor;
import lime.system.System;
import flixel.FlxSprite;

import openfl.text.TextFormat;
import openfl.Lib;
import flixel.FlxG;
import openfl.display.Sprite;

import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.display.Bitmap;

class AchievementsToastManager extends Sprite {

    public static var ENTER_TIME:Float = 0.6;
    public static var DISPLAY_TIME:Float = 4.0;
    public static var LEAVE_TIME:Float = 0.6;
    public static var TOTAL_TIME:Float = ENTER_TIME + DISPLAY_TIME + LEAVE_TIME;

    var playTime:FlxTimer = new FlxTimer();

    public function new()
    {
        super();
        FlxG.signals.postStateSwitch.add(onStateSwitch);
        FlxG.signals.gameResized.add(onWindowResized);
    }

    /**
     * Create a toast!
     * @param iconPath
     * @param title 
     * @param descript
     * @param sound 
     */
    public function createToast(iconPath:String, title:String, description:String, ?sound:Bool = false, ?color:String = '#3848CC'):Void
    {
        if (sound) FlxG.sound.play(Paths.sound('Ach'+FlxG.random.int(3, 4))); 
        
        var toast = new AchievementsToast(iconPath, title, description, color);
        addChild(toast);

        playTime.start(TOTAL_TIME);
        playToasts();
    }

    public function playToasts():Void
    {
        for (i in 0...numChildren)
        {
            var child = getChildAt(i);
            FlxTween.cancelTweensOf(child);
            FlxTween.tween(child, {y: (numChildren - 1 - i) * child.height}, ENTER_TIME, {ease: FlxEase.quadOut,
                onComplete: function(tween:FlxTween)
                {
                    FlxTween.cancelTweensOf(child);
                    FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut, startDelay: DISPLAY_TIME,
                        onComplete: function(tween:FlxTween)
                        {
                            cast(child, AchievementsToast).removeChildren();
                            removeChild(child);
                        }
                    });
                }
            });
        }
    }

    public function collapseToasts():Void
    {
        for (i in 0...numChildren)
        {
            var child = getChildAt(i);
            FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut,
                onComplete: function(tween:FlxTween)
                {
                    cast(child, AchievementsToast).removeChildren();
                    removeChild(child);
                }
            });
        }
    }

    public function onStateSwitch():Void
    {
        if (!playTime.active)
            return;

        var elapsedSec = playTime.elapsedTime / 1000;
        if (elapsedSec < ENTER_TIME)
        {
            for (i in 0...numChildren)
            {
                var child = getChildAt(i);
                FlxTween.cancelTweensOf(child);
                FlxTween.tween(child, {y: (numChildren - 1 - i) * child.height}, ENTER_TIME - elapsedSec, {ease: FlxEase.quadOut,
                    onComplete: function(tween:FlxTween)
                    {
                        FlxTween.cancelTweensOf(child);
                        FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut, startDelay: DISPLAY_TIME,
                            onComplete: function(tween:FlxTween)
                            {
                                cast(child, AchievementsToast).removeChildren();
                                removeChild(child);
                            }
                        });
                    }
                });
            }
        }
        else if (elapsedSec < DISPLAY_TIME)
        {
            for (i in 0...numChildren)
            {
                var child = getChildAt(i);
                FlxTween.cancelTweensOf(child);
                FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut, startDelay: DISPLAY_TIME - (elapsedSec - ENTER_TIME),
                    onComplete: function(tween:FlxTween)
                    {
                        cast(child, AchievementsToast).removeChildren();
                        removeChild(child);
                    }
                });
            }
        }
        else if (elapsedSec < LEAVE_TIME)
        {
            for (i in 0...numChildren)
            {
                var child = getChildAt(i);
                FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME -  (elapsedSec - ENTER_TIME - DISPLAY_TIME), {ease: FlxEase.quadOut,
                    onComplete: function(tween:FlxTween)
                    {
                        cast(child, AchievementsToast).removeChildren();
                        removeChild(child);
                    }
                });
            }
        }
    }

    public function onWindowResized(x:Int, y:Int):Void
    {
        for (i in 0...numChildren)
        {
            var child = getChildAt(i);
            child.x = Lib.current.stage.stageWidth - child.width;
        }
    }


}

class AchievementsToast extends Sprite {

    var back:Bitmap;
    var icon:Bitmap;
    var title:TextField;
    var desc:TextField;

    public function new(iconPath:String, titleText:String, description:String, ?color:String = '#3848CC')
    {
        super();
        back = new Bitmap(new BitmapData(600, 150, true, 0xFF000000));
        back.alpha = 0.9;
        back.x = 0;
        back.y = 0;

        var iconBmp = FlxG.bitmap.add(Paths.image('achieve/types/'+iconPath));
        iconBmp.persist = true;
        
        if(iconPath != null)
        {
            icon = new Bitmap(iconBmp.bitmap);
            icon.width = 154;
            icon.height = 100;
            icon.x = 10;
            icon.y = 15;
        }

        title = new TextField();
        title.text = titleText/*.toUpperCase()*/;
        title.setTextFormat(new TextFormat('VCR OSD Mono', 28, FlxColor.fromString(color), true));
        title.wordWrap = true;
        title.width = 426;
        title.height = 55;
        iconPath!=null ? title.x = 174 : title.x = 5;
        title.y = 10;

        desc = new TextField();
        desc.text = description/*.toUpperCase()*/;
        desc.setTextFormat(new TextFormat('VCR OSD Mono', 22, FlxColor.WHITE));
        desc.wordWrap = true;
        desc.width = 400;
        //desc.height = 60;
        iconPath!=null ?  desc.x = 174 : desc.x = 5;
        desc.y = 45;
        if (titleText.length >= 28/* || titleText.contains("\n")*/)
        {   
            desc.y += 25;
            //desc.height -= 25;
        }

        addChild(back);
        if(iconPath!=null) addChild(icon);

        addChild(title);
        addChild(desc);

        width = back.width;
        height = back.height;
        x = Lib.current.stage.stageWidth - width;
        y = -height;
    }


}
