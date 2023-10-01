
function newPost() {
 for (membe in grpMenuShit.members) {
  membe.xAdd -= 1000;
  membe.alpha = -1;
  membe.y = (membe.targetY * membe.yMult) + (FlxG.height * 0.48) + membe.yAdd * 11;
  FlxTween.tween(membe, {
	xAdd: 0,
	alpha: 1
  }, .75, {ease: FlxEase.smoothStepOut});
 }
}

function onChangeSelectionPost(change) {
 var bullShit:Int = 0;
 for (i in 0...grpMenuShit.members.length) {
  bullShit++;
  grpMenuShit.members[i].targetY = bullShit - curSelected - 0.75;
 }
}
