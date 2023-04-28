package grafex.sprites.menu;

import grafex.sprites.attached.AttachedSprite;

class MainMenuButton extends AttachedSprite {

    public var itemName:String;
    public var num:Int;
    public var locked:Bool = false;

    public function new(x:Float, y:Float, name:String, num:Int, locked:Bool = false) {
        super();
        setButton(x, y, name, num, locked);
    }

    var standartPath:String = 'newmenu/menu_';

    private function setButton(x:Float, y:Float, name:String, num:Int, locked:Bool = false) {
        this.frames = Paths.getSparrowAtlas(standartPath + name, null, false);
        this.animation.addByPrefix('idle', name + " basic", 24);
        this.animation.addByPrefix('selected', name + " white", 24);
        this.animation.play('idle');
        this.num = num;
        this.scrollFactor.set();
        this.antialiasing = ClientPrefs.globalAntialiasing;
        this.updateHitbox();
        this.setPosition(x, y);
        this.itemName = name;
        this.locked = locked;

        //var popUpCock:MainMenuButtonPopUp = new MainMenuButtonPopUp(this.width, this.height, name, num, locked);
    }

    public function selectFunc() {
        

    } 

    override function update(elapsed) {
        super.update(elapsed);
    }
}

class MainMenuButtonPopUp extends AttachedSprite {

    var standartPath:String = 'newmenu/popUps';
    public var type:String; //For public checks

    public function new(parentWidth:Float, parentHeight:Float, name:String, num:Int, locked:Bool = false) {
        super();
        type = getType(name);
        setupPopUp(parentWidth, parentWidth);
    }

    function setupPopUp(ox:Float, oy:Float) {
        this.frames = Paths.getSparrowAtlas(standartPath);
        this.animation.addByPrefix('idle', type, 24);
        this.animation.play('idle');

    }

    private function getType(name:String = 'story_mode'):String 
    {
        //switch(name){
        //    case 'story_mode': return 'NEW';
        //    case 'freeplay': return 'SONG UNLOCKED';
       // } 

       return 'NEW';
    }

    public function dance() {
        
    }


}