function onBeatHit(b) {
	FlxG.camera.zoom += 0.025;
	FlxTween.tween(FlxG.camera, {zoom: 1}, 0.2);
} //Thats all

