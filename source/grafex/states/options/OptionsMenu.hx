package grafex.states.options;

import grafex.states.options.substates.NoteOffsetState;
import grafex.states.substates.PauseSubState;
import grafex.states.options.substates.NotesSubState;
import grafex.system.statesystem.MusicBeatState;
import grafex.states.substates.LoadingState;
import grafex.system.Paths;

import grafex.system.statesystem.MusicBeatSubstate;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.Lib;
import grafex.states.options.substates.Options;
import grafex.states.options.substates.ControlsSubState;
import grafex.util.Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import grafex.util.ClientPrefs;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;

class OptionCata extends FlxSprite
{
	public var title:String;
	public var options:Array<Option>;

	public var optionObjects:FlxTypedGroup<FlxText>;

	public var titleObject:FlxText;

	public var middle:Bool = false;

	public function new(x:Float, y:Float, _title:String, _options:Array<Option>, middleType:Bool = false)
	{
		super(x, y);
		title = _title;
		middle = middleType;
		if (!middleType)
			makeGraphic(295, 64, FlxColor.BLACK);
		alpha = 0.4;

		options = _options;

		optionObjects = new FlxTypedGroup();

		titleObject = new FlxText((middleType ? 1180 / 2 : x), y + (middleType ? 0 : 16), 0, title);
		titleObject.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleObject.borderSize = 3;

		if (middleType)
		{
			titleObject.x = 50 + ((1180 / 2) - (titleObject.fieldWidth / 2));
		}
		else
			titleObject.x += (width / 2) - (titleObject.fieldWidth / 2);

		titleObject.scrollFactor.set();

		scrollFactor.set();

		for (i in 0...options.length)
		{
			var opt = options[i];
			var text:FlxText = new FlxText((middleType ? 1180 / 2 : 72), titleObject.y + 54 + (46 * i), 0, opt.getValue());
			if (middleType)
			{
				text.screenCenter(X);
			}
			text.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 3;
			text.borderQuality = 1;
			text.scrollFactor.set();
			optionObjects.add(text);
		}
	}

	public function changeColor(color:FlxColor)
	{
		makeGraphic(295, 64, color);
	}
}

class OptionsMenu extends MusicBeatSubstate
{
	public static var instance:OptionsMenu;

	public var background:FlxSprite;

	public var selectedCat:OptionCata;

	public var selectedOption:Option;

	public var selectedCatIndex = 0;
	public var selectedOptionIndex = 0;

	public var isInCat:Bool = false;

	public var options:Array<OptionCata>;

	public static var isInPause = false;

	var restoreSettingsText:FlxText;

	public var shownStuff:FlxTypedGroup<FlxText>;

	public static var visibleRange = [114, 640];

	var startSong = true;

	public function new(pauseMenu:Bool = false)
	{
		super();

		isInPause = pauseMenu;
	}

	public var menu:FlxTypedGroup<FlxSprite>;

	public var descText:FlxText;
	public var descBack:FlxSprite;

	override function create()
	{

		options = [
			new OptionCata(50, 40, "Gameplay", [
				//new OffsetThing("Change the note visual offset (how many milliseconds a note looks like it is offset in a chart)"),
				new HitSoundOption("Adds 'hitsound' on note hits."),
				new GhostTapOption("Toggle counting pressing a directional input when no arrow is there as a miss."),
				new DownscrollOption("Toggle making the notes scroll down rather than up."),
				new InstantRespawn("Toggle if you instantly respawn after dying."),
				new CamZoomOption("Toggle the camera zoom in-game."),
                new ControllerMode("Enables you to play with controller."),
                new DFJKOption(),
                new NotesOption(),
                new Customizeption(),
				new Judgement("Create a custom judgement preset"),
				new Shouldcameramove("Moves camera on opponent/player note hits."),
			]),
			new OptionCata(345, 40, "Appearance", [
				new MiddleScrollOption("Put your lane in the center or on the right."), 
 				new ClassicScoreTxt("ScoreTxt like in OG FNF."), 
				new LightCpuStrums("Talks itself, bruh."),
				new MissSoundsOption("Toggle miss sounds playing when you don't hit a note."),
				new ShowSplashes("Show particles on SICK hit."),
				new NoteSplashesScale("Change NoteSplashes Scale."),
				new NoteSplashesAlpha("Change NoteSplashes Alpha."),
				new ShowSusSplashes("Show light on Sustain Notes Hit."),
				new NoteSusSplashesAlpha("Change Sustain Note Splash-Light Alpha."),
				new SustainNotesClipRectOption("Chooses a style for hold note clippings. StepMania: Holds under Receptors. FNF: Holds over receptors."),
				new HealthBarOption("Toggles health bar visibility."),
				new EnableTimeBar("Toggles time bar visibility."),
				new HideHud("Shows to you hud."),
				new ScoreZoom("Zoom score on 2'nd beat."),
			]),
			new OptionCata(640, 40, "Misc", [
				new FlashingLightsOption("Toggle flashing lights that can cause epileptic seizures and strain."),
				new ColorBlindOption("You can set colorblind filter (makes the game more playable for colorblind people)."),
				new ShadersOption("Shaders used for some visual effects, and also CPU intensive for weaker PCs."),
				new FPSOption("Toggle the FPS Counter."),
                new MEMOption("Toggle the MEM Counter."),
				#if desktop new FPSCapOption("Change your FPS Cap."),
				#end
                new AutoPause("Stops game, when its unfocused"),
                new AntialiasingOption("Toggle antialiasing, improving graphics quality at a slight performance penalty."),
                new QualityLow("Turn off some object on stages"),
				//new Imagepersist("Images loaded will stay in memory until the game is closed."),
        		]),
			new OptionCata(935, 40, "Extra", [
				new AutoSave("Turn AutoSaves your chating in Charting state."),
				new AutoSaveInt("Change Chart AutoSave Interval."),
			    new PauseCountDownOption("Toggle countdown after pressing 'Resume' in Pause Menu."),
			]),
			new OptionCata(-1, 125, "Editing Keybinds", [/* nothing here lol - PurSnake*/], true),

			new OptionCata(-1, 125, "Editing Judgements", [
				new SickMSOption("How many milliseconds are in the SICK hit window"),
				new GoodMsOption("How many milliseconds are in the GOOD hit window"),
				new BadMsOption("How many milliseconds are in the BAD hit window"),
			], true)
		];

		instance = this;

		menu = new FlxTypedGroup<FlxSprite>();

		shownStuff = new FlxTypedGroup<FlxText>();

		background = new FlxSprite(50, 40).makeGraphic(1180, 640, FlxColor.BLACK);
		background.alpha = 0.5;
		background.scrollFactor.set();
		menu.add(background);

		descBack = new FlxSprite(50, 640).makeGraphic(1180, 38, FlxColor.BLACK);
		descBack.alpha = 0.3;
		descBack.scrollFactor.set();
		menu.add(descBack);

		if (isInPause)
		{
			var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0;
			bg.scrollFactor.set();
			menu.add(bg);

			background.alpha = 0.3;
			bg.alpha = 0.4;

			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}

		selectedCat = options[0];

		selectedOption = selectedCat.options[0];

		add(menu);

		add(shownStuff);

		for (i in 0...options.length - 1)
		{
			if (i >= 4)
				continue;
			var cat = options[i];
			add(cat);
			add(cat.titleObject);
		}

		descText = new FlxText(62, 648);
		descText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 2;

		add(descBack);
		add(descText);

		isInCat = true;

		switchCat(selectedCat);

		selectedOption = selectedCat.options[0];

		restoreSettingsText = new FlxText (62, 680, FlxG.width, 'Press DELETE to reset settings');
		restoreSettingsText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		restoreSettingsText.scrollFactor.set();
		restoreSettingsText.borderSize = 2;
		restoreSettingsText.borderQuality = 3;
		add(restoreSettingsText);

		super.create();
	}

	public function switchCat(cat:OptionCata, checkForOutOfBounds:Bool = true)
	{
		try
		{
			visibleRange = [114, 640];
			if (cat.middle)
				visibleRange = [Std.int(cat.titleObject.y), 640];
			if (selectedOption != null)
			{
				var object = selectedCat.optionObjects.members[selectedOptionIndex];
				object.text = selectedOption.getValue();
			}

			if (selectedCatIndex > options.length - 3 && checkForOutOfBounds)
				selectedCatIndex = 0;

			if (selectedCat.middle)
				remove(selectedCat.titleObject);

			selectedCat.changeColor(FlxColor.BLACK);
			selectedCat.alpha = 0.3;

			for (i in 0...selectedCat.options.length)
			{
				var opt = selectedCat.optionObjects.members[i];
				opt.y = selectedCat.titleObject.y + 54 + (46 * i);
			}

			while (shownStuff.members.length != 0)
			{
				shownStuff.members.remove(shownStuff.members[0]);
			}
			selectedCat = cat;
			selectedCat.alpha = 0.2;
			selectedCat.changeColor(FlxColor.WHITE);

			if (selectedCat.middle)
				add(selectedCat.titleObject);

			for (i in selectedCat.optionObjects)
				shownStuff.add(i);

			selectedOption = selectedCat.options[0];

			if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
			{
				for (i in 0...selectedCat.options.length)
				{
					var opt = selectedCat.optionObjects.members[i];
					opt.y = selectedCat.titleObject.y + 54 + (46 * i);
				}
			}

			selectedOptionIndex = 0;

			if (!isInCat)
				selectOption(selectedOption);

			for (i in selectedCat.optionObjects.members)
			{
				if (i.y < visibleRange[0] - 24)
					i.alpha = 0;
				else if (i.y > visibleRange[1] - 24)
					i.alpha = 0;
				else
				{
					i.alpha = 0.4;
				}
			}
		}
		catch (e)
		{
			trace("oops\n" + e);
			selectedCatIndex = 0;
		}
	}

	public function selectOption(option:Option)
	{
		var object = selectedCat.optionObjects.members[selectedOptionIndex];

		selectedOption = option;

		if (!isInCat)
		{
			object.text = option.getValue();

			descText.text = option.getDescription();
		}
	}

	public static function openControllsState()
		{
			MusicBeatState.switchState(new ControlsSubState());
			ClientPrefs.saveSettings();
		}

	public static function openNotesState()
		{
			MusicBeatState.switchState(new NotesSubState());
			ClientPrefs.saveSettings();
		}

    public static function openAjustState()
		{
			LoadingState.loadAndSwitchState(new NoteOffsetState());
			ClientPrefs.saveSettings();
		}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (c in options) {
			c.titleObject.text = c.title;
			for (o in 0...c.optionObjects.length) {
				c.optionObjects.members[o].text = c.options[o].getValue();
			}
		}

		if(FlxG.keys.justPressed.F11)
			{
			FlxG.fullscreen = !FlxG.fullscreen;
			}

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var accept = false;
		var right = false;
		var left = false;
		var up = false;
		var down = false;
		var any = false;
		var escape = false;
		var reset = false;

		accept = controls.ACCEPT;
		right = controls.UI_RIGHT_P;
		left = controls.UI_LEFT_P;
		up = controls.UI_UP_P;
		down = controls.UI_DOWN_P;

		any = FlxG.keys.justPressed.ANY || (gamepad != null ? gamepad.justPressed.ANY : false);
		escape = controls.BACK;
		reset = controls.RESET;

		if (selectedCat != null && !isInCat)
		{
			for (i in selectedCat.optionObjects.members)
			{
				if (selectedCat.middle)
				{
					i.screenCenter(X);
				}

				// I wanna die!!!
				if (i.y < visibleRange[0] - 24)
					i.alpha = 0;
				else if (i.y > visibleRange[1] - 24)
					i.alpha = 0;
				else
				{
					if (selectedCat.optionObjects.members[selectedOptionIndex].text != i.text)
						i.alpha = 0.4;
					else
						i.alpha = 1;
				}
			}
		}

		try
		{
			if (isInCat)
			{
				descText.text = "Please select a category";
				if (right || FlxG.mouse.wheel < 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();

					selectedCatIndex = FlxMath.wrap(selectedCatIndex + 1, 0, options.length - 3);

					switchCat(options[selectedCatIndex]);
				}
				else if (left || FlxG.mouse.wheel > 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();

					selectedCatIndex = FlxMath.wrap(selectedCatIndex - 1, 0, options.length - 3);

					switchCat(options[selectedCatIndex]);
				}

				if (accept || FlxG.mouse.justPressed)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					selectedOptionIndex = 0;
					isInCat = false;
					selectOption(selectedCat.options[0]);
				}

				if(reset)
				{
					if (!isInPause)
					{
						resetOptions();
						restoreSettingsText.text = 'Settings restored // Restarting game';
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							TitleState.initialized = false;
                            TitleState.closedState = false;
                            FlxG.sound.music.fadeOut(0.3);
                            FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
						});
					}
					else
					{
						restoreSettingsText.text = 'Unable in PauseMenu';
					}
				}

				if (escape)
				{
					if (!isInPause) {
					    ClientPrefs.saveSettings();
						MusicBeatState.switchState(new MainMenuState());
						ControlsSubState.fromcontrols = false;
					    }
					else
					{
						PauseSubState.goBack = true;
						ClientPrefs.saveSettings();
						close();
					}
				}
			}
			else
			{
				if (selectedOption != null)
					if (selectedOption.acceptType)
					{
						if (escape && selectedOption.waitingType)
						{
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
							selectedOption.waitingType = false;
							var object = selectedCat.optionObjects.members[selectedOptionIndex];
							object.text = selectedOption.getValue();
							//Debug.logTrace("New text: " + object.text);
							return;
						}
						else if (any)
						{
							var object = selectedCat.optionObjects.members[selectedOptionIndex];
							selectedOption.onType(gamepad == null ? FlxG.keys.getIsDown()[0].ID.toString() : gamepad.firstJustPressedID());
							object.text = selectedOption.getValue();
						//	Debug.logTrace("New text: " + object.text);
						}
					}
				if (selectedOption.acceptType || !selectedOption.acceptType)
				{
					if (accept || FlxG.mouse.justPressed)
					{
						var prev = selectedOptionIndex;
						var object = selectedCat.optionObjects.members[selectedOptionIndex];
						selectedOption.press();

						if (selectedOptionIndex == prev)
						{
							ClientPrefs.saveSettings();

							object.text = selectedOption.getValue();
						}
					}

					if (down || FlxG.mouse.wheel < 0)
					{
						if (selectedOption.acceptType)
							selectedOption.waitingType = false;
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
						selectedOptionIndex++;

						// just kinda ignore this math lol

						if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
						{
							for (i in 0...selectedCat.options.length)
							{
								var opt = selectedCat.optionObjects.members[i];
								opt.y = selectedCat.titleObject.y + 54 + (46 * i);
							}
							selectedOptionIndex = 0;
						}

						if (selectedOptionIndex != 0
							&& selectedOptionIndex != options[selectedCatIndex].options.length - 1
							&& options[selectedCatIndex].options.length > 6)
						{
							if (selectedOptionIndex >= (options[selectedCatIndex].options.length - 1) / 2)
								for (i in selectedCat.optionObjects.members)
								{
									i.y -= 46;
								}
						}

						selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
					}
					else if (up || FlxG.mouse.wheel > 0)
					{
						if (selectedOption.acceptType)
							selectedOption.waitingType = false;
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
						selectedOptionIndex--;

						// just kinda ignore this math lol

						if (selectedOptionIndex < 0)
						{
							selectedOptionIndex = options[selectedCatIndex].options.length - 1;

							if (options[selectedCatIndex].options.length > 6)
								for (i in selectedCat.optionObjects.members)
								{
									i.y -= (46 * ((options[selectedCatIndex].options.length - 1) / 2));
								}
						}

						if (selectedOptionIndex != 0 && options[selectedCatIndex].options.length > 6)
						{
							if (selectedOptionIndex >= (options[selectedCatIndex].options.length - 1) / 2)
								for (i in selectedCat.optionObjects.members)
								{
									i.y += 46;
								}
						}

						if (selectedOptionIndex < (options[selectedCatIndex].options.length - 1) / 2)
						{
							for (i in 0...selectedCat.options.length)
							{
								var opt = selectedCat.optionObjects.members[i];
								opt.y = selectedCat.titleObject.y + 54 + (46 * i);
							}
						}

						selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
					}

					if (right)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						var object = selectedCat.optionObjects.members[selectedOptionIndex];
						selectedOption.right();

						ClientPrefs.saveSettings();

						object.text = selectedOption.getValue();
						//Debug.logTrace("New text: " + object.text);
					}
					else if (left)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						var object = selectedCat.optionObjects.members[selectedOptionIndex];
						selectedOption.left();

						ClientPrefs.saveSettings();

						object.text = selectedOption.getValue();
						//Debug.logTrace("New text: " + object.text);
					}

					if(reset)
					{
						if (!isInPause)
						{
							resetOptions();
							restoreSettingsText.text = 'Settings restored // Restarting game';
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
							new FlxTimer().start(1.5, function(tmr:FlxTimer)
							{
								TitleState.initialized = false;
                                TitleState.closedState = false;
                                FlxG.sound.music.fadeOut(0.3);
                                FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
							});
						}
						else
						{
							restoreSettingsText.text = 'Unable in PauseMenu';
						}
					}

					if (escape)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

						if (selectedCatIndex >= 4)
							selectedCatIndex = 0;

						for (i in 0...selectedCat.options.length)
						{
							var opt = selectedCat.optionObjects.members[i];
							opt.y = selectedCat.titleObject.y + 54 + (46 * i);
						}
						selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
						isInCat = true;
						if (selectedCat.optionObjects != null)
							for (i in selectedCat.optionObjects.members)
							{
								if (i != null)
								{
									if (i.y < visibleRange[0] - 24)
										i.alpha = 0;
									else if (i.y > visibleRange[1] - 24)
										i.alpha = 0;
									else
									{
										i.alpha = 0.4;
									}
								}
							}
						if (selectedCat.middle)
							switchCat(options[0]);
					}
				}
			}
		}
		catch (e)
		{
			//Debug.logError("wtf we actually did something wrong, but we dont crash bois.\n" + e);
            FlxG.log.add("wtf we actually did something wrong, but we dont crash bois.\n" + e);
			selectedCatIndex = 0;
			selectedOptionIndex = 0;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			if (selectedCat != null)
			{
				for (i in 0...selectedCat.options.length)
				{
					var opt = selectedCat.optionObjects.members[i];
					opt.y = selectedCat.titleObject.y + 54 + (46 * i);
				}
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
				isInCat = true;
			}
		}
	}

	public static function resetOptions()
	{
		FlxG.save.data.autoPause = null;
		FlxG.save.data.visibleHealthbar = null;
		FlxG.save.data.showjud = null;
        FlxG.save.data.showCombo = null;
        FlxG.save.data.blurNotes = null;
		FlxG.save.data.playmissanims = null;
        FlxG.save.data.instantRespawn = null;
        FlxG.save.data.playmisssounds = null;
        FlxG.save.data.hitsound = null;
        FlxG.save.data.shouldcameramove = null;
        FlxG.save.data.hliconbop = null;
        FlxG.save.data.hliconbopNum = null;
        FlxG.save.data.noteSkin = null;
        FlxG.save.data.noteSkinNum = null;
		FlxG.save.data.chartautosaveInterval = null;
        FlxG.save.data.skipTitleState = null;
		FlxG.save.data.chartautosave = null;
        FlxG.save.data.downScroll = null;
		FlxG.save.data.ratingSystem = null;
		FlxG.save.data.ratingSystemNum = null;
 		FlxG.save.data.SusTransper = null;
		FlxG.save.data.songNameDisplay = null;
		FlxG.save.data.vintageOnGame = null;
		FlxG.save.data.middleScroll = null;
		FlxG.save.data.countdownpause = null;
		FlxG.save.data.showFPS = null;
        FlxG.save.data.showMEM = null;
		FlxG.save.data.flashing = null;
		FlxG.save.data.globalAntialiasing = null;
		FlxG.save.data.noteSplashes = null;
		FlxG.save.data.lowQuality = null;
		FlxG.save.data.framerate = null;
		FlxG.save.data.ColorBlindType = null;
		FlxG.save.data.camZooms = null;
		FlxG.save.data.noteOffset = null;
		FlxG.save.data.hideHud = null;
		FlxG.save.data.arrowHSV = null;
		FlxG.save.data.imagesPersist = null;
		FlxG.save.data.ghostTapping = null;
		FlxG.save.data.timeBarType = null;
		FlxG.save.data.timeBarTypeNum = null;
		FlxG.save.data.scoreZoom = null;
		FlxG.save.data.noReset = null;
        FlxG.save.data.underdelayalpha = null;
        FlxG.save.data.underdelayonoff = null;
		FlxG.save.data.hideOpponenStrums = null;
		FlxG.save.data.healthBarAlpha = 1;
        FlxG.save.data.hsvol = null;
		FlxG.save.data.comboOffset = null;
		FlxG.save.data.ratingOffset = null;
		FlxG.save.data.sickWindow = null;
		FlxG.save.data.goodWindow = null;
		FlxG.save.data.badWindow = null;
		FlxG.save.data.safeFrames = null;
		FlxG.save.data.gameplaySettings = null;
		FlxG.save.data.controllerMode = null;
		FlxG.save.data.customControls = ClientPrefs.keyBinds;
		FlxG.save.data.shaders = null;
	
        ClientPrefs.loadPrefs();

	}
}

