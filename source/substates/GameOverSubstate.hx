package substates;

import backend.WeekData;

import objects.Character;
import flixel.FlxObject;
import flixel.FlxSubState;
import objects.Note;
import states.StoryMenuState;
import states.FreeplayState;
import objects.StrumNote;
import torchsthings.objects.ReflectedChar;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	var camFollow:FlxObject;
	var moveCamera:Bool = false;
	var playingDeathSound:Bool = false;
	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;
	//nos vamos a morir XD
	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';

		var _song = PlayState.SONG;
		if(_song != null)
		{
			if(_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
			if(_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
			if(_song.gameOverLoop != null && _song.gameOverLoop.trim().length > 0) loopSoundName = _song.gameOverLoop;
			if(_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) endSoundName = _song.gameOverEnd;
		}
	}

	// XD
	var charX:Float = 0;
	var charY:Float = 0;
	override function create()
	{
		var offsetX:Float = 0;
		var offsetY:Float = 0;
		instance = this;

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width * 10, FlxG.height * 10);
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		PlayState.instance.camHUD.visible = false;

		Conductor.songPosition = 0;

		var playBF:String = PlayState.instance.boyfriend.curCharacter;
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.getPath('characters/$playBF-dead.json', TEXT, null, true)))
		#else
		if (Assets.exists(Paths.getPath('characters/$playBF-dead.json', TEXT, null, true)))
		#end
		{characterName = playBF + '-dead';}

		boyfriend = new Character(PlayState.instance.boyfriend.getScreenPosition().x, PlayState.instance.boyfriend.getScreenPosition().y, characterName, true);
		boyfriend.x = PlayState.instance.boyfriend.x + offsetX;
		boyfriend.y = PlayState.instance.boyfriend.y + offsetY;
		for (stage in PlayState.instance.stages) {
			if(stage != null && stage.exists && stage.active && stage.reflectedBF != null) {
				var reflected:ReflectedChar = new ReflectedChar(boyfriend, 0.35);
				add(reflected);
			}
		}
		add(boyfriend);
		PlayState.instance.boyfriend.visible = false;

		FlxG.sound.play(Paths.sound(deathSoundName));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(boyfriend.getGraphicMidpoint().x + boyfriend.cameraPosition[0], boyfriend.getGraphicMidpoint().y + boyfriend.cameraPosition[1]);
		FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
		add(camFollow);

		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.5, {ease: FlxEase.elasticInOut});
		
		PlayState.instance.setOnScripts('inGameOver', true);
		PlayState.instance.callOnScripts('onGameOverStart', []);
		PlayState.instance.stageGameOver();
		
		switch(characterName)
		{
			case "pico-blazin" | "pico-dead" | "pico-explosion-dead":
				bg.alpha = 1;
			default:
				bg.alpha = 0;
				FlxTween.tween(bg, {alpha: 0.5}, 0.4, {ease: FlxEase.linear});
		}

		super.create();
	}

	public var startedDeath:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			if (PlayState.SONG.song.toLowerCase() == 'test') {
				PlayState.fixNoteskinAfterTestSongFinishes();
			}

			Mods.loadTopMod();
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}
		
		if (boyfriend.animation.curAnim != null)
		{
			if (boyfriend.animation.curAnim.name == 'firstDeath' && boyfriend.animation.curAnim.finished && startedDeath)
				boyfriend.playAnim('deathLoop');

			if(boyfriend.animation.curAnim.name == 'firstDeath')
			{
				if(boyfriend.animation.curAnim.curFrame >= 12 && !moveCamera)
				{
					FlxG.camera.follow(camFollow, LOCKON, 0.6);
					moveCamera = true;
				}

				if (boyfriend.animation.curAnim.finished && !playingDeathSound)
				{
					startedDeath = true;
					if (PlayState.SONG.stage == 'tank')
					{
						playingDeathSound = true;
						coolStartDeath(0.2);
						
						var exclude:Array<Int> = [];
						//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

						FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
							if(!isEnding)
							{
								FlxG.sound.music.fadeIn(0.2, 1, 4);
							}
						});
					}
					else coolStartDeath();
				}
			}
		}
		
		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
