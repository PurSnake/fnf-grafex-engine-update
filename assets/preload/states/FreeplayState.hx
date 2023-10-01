function onUpdate(elapsed) {
 for (healtIcon in iconArray) {
  var mult:Float = FlxMath.lerp(healtIcon.customScale, healtIcon.scale.x, Utils.boundTo(1 - (elapsed * 9), 0, 1));
  healtIcon.scale.set(mult, mult);
  healtIcon.updateHitbox();
 }
 var bgMult:Float = FlxMath.lerp(1.1, bg.scale.x, Utils.boundTo(1 - (elapsed * 9), 0, 1));
 bg.scale.set(bgMult, bgMult);
 bg.screenCenter();

}

function onBeatHit(da) {
 for (healtIcon in iconArray) healtIcon.doScale(0.925);

 bg.scale.set(1.135, 1.135);
}