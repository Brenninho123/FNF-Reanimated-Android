package torchsthings.objects;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import objects.NoteSplash.PixelSplashShaderRef;
import objects.StrumNote;
import objects.Note;
import flixel.system.FlxAssets.FlxShader;
import openfl.utils.Assets;

using StringTools;

class NoteStrumCover extends FlxSprite {
	public static var defaultCoverSkin(default, never):String = 'strumCovers/NOTE_covers';
    public static var defaultLibrary(default, never):String = 'shared';
    var colArray:Array<String> = Note.colArray;
    public var strumNote:StrumNote;
    var posOffset:Array<Int> = [-25, -5];
    var animOffsets:Array<Array<Int>> = [/*start*/[20, 15], /*hold*/[-25, -5], /*end*/[-65, -40]];
	public var rgbShader:RGBShaderReference;
    public var pixelShader:PixelSplashShaderRef;
    var assets:String = '';

    public function new(refNote:StrumNote, ?texture:String = 'strumCovers/NOTE_covers', ?library:String = 'shared', ?rgbEnabled:Bool = true) {
        super(0, 0);

        strumNote = refNote;
        if(texture == null) texture = defaultCoverSkin;
        if(library == null) library = defaultLibrary;

        reloadCover(texture, library, rgbEnabled);

        visible = false;
    }

    function getOffsetsFromFile(?coverTexture:String = 'strumCovers/NOTE_covers', ?library:String = 'shared'):Array<Array<Int>> {
        var tempOffsetArray = Assets.getText(Paths.txt(coverTexture, library).replace('data/', 'images/')).trim().split("\n");
        var returnArr:Array<Array<Int>> = [/*start*/[20, 15], /*hold*/[-25, -5], /*end*/[-65, -40]];

        for (i in 0...tempOffsetArray.length) {
            var arr1:Array<String> = tempOffsetArray[i].split(":");
            var arr2:Array<String> = arr1[1].split(",");
            switch(arr1[0]) {
                case 'start':
                    returnArr.insert(0, [Std.parseInt(arr2[0]), Std.parseInt(arr2[1])]);
                case 'hold':
                    returnArr.insert(1, [Std.parseInt(arr2[0]), Std.parseInt(arr2[1])]);
                case 'end':
                    returnArr.insert(2, [Std.parseInt(arr2[0]), Std.parseInt(arr2[1])]);
            }
        }

        return returnArr;
    }

    override function update(elapsed:Float) {
        if (strumNote == null) {destroy();}
        x = strumNote.x + posOffset[0];
        y = strumNote.y + posOffset[1];
        super.update(elapsed);
    }

    var isAltNote:Bool = false;

    public function start(?note:Note = null) {
        visible = true;
        if (note != null && altSkin(assets) && note.noteType == 'Alt Animation') {
            animation.play('start-alt');
            isAltNote = true;
        } else {
            animation.play("start");
            isAltNote = false;
        }
    }

    public function end(playSplash:Bool) {
        visible = playSplash;
        posOffset = animOffsets[2]; // For End Anim Offset
        animation.play("end" + (isAltNote ? '-alt' : ''), true);
    }

    function daCallback(anim:String) {
        switch (anim) {
            case "start" | 'start-alt':
                posOffset = animOffsets[1]; // For Hold Anim Offset
                animation.play("hold" + (isAltNote ? '-alt' : ''));

            case "end" | 'end-alt':
                posOffset = animOffsets[0]; // For Start Anim Offset
                visible = false;
        }
    }

    function altSkin(?assets:String = ''):Bool {
		var tableOfSkins:Array<String> = [
			'custom_notes/covers/parents'
		];

        for (skin in tableOfSkins) {
            if (assets.startsWith(skin)) {
                return true;
            }
        }
		return false;
	}

    public function reloadCover(?texture:String = 'strumCovers/NOTE_covers', ?library:String = 'shared', ?rgbEnabled:Bool = true) {
        {
            var lastAnim:String = null;
            if(animation.curAnim != null) lastAnim = animation.curAnim.name;

            // Failsafe
            if ((texture.startsWith('custom_notes/covers/') && !Paths.fileExists('images/' + texture + '.png', IMAGE, true, library)) || (texture.startsWith('strumCovers/') && ClientPrefs.data.noteSkin == 'Character Based')) {
                texture = 'custom_notes/covers/normal';
                library = 'torchs_assets';
            }
            
            assets = texture;

            frames = Paths.getSparrowAtlas(texture, library);
            antialiasing = ClientPrefs.data.antialiasing;
            animation.addByPrefix('start', colArray[strumNote.noteData] + "CoverStart0", 24, false);
            animation.addByPrefix('hold', colArray[strumNote.noteData] + "Cover0", 24, true);
            animation.addByPrefix('end', colArray[strumNote.noteData] + "CoverEnd0", 24, false);
            if (altSkin(texture)) {
                animation.addByPrefix('start-alt', colArray[strumNote.noteData] + "CoverStart-alt", 24, false);
                animation.addByPrefix('hold-alt', colArray[strumNote.noteData] + "Cover-alt", 24, true);
                animation.addByPrefix('end-alt', colArray[strumNote.noteData] + "CoverEnd-alt", 24, false);
            }
            animation.finishCallback = daCallback;
            animation.play("end");
            
            rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(strumNote.noteData));
            rgbShader.enabled = rgbEnabled;
            if(strumNote.noteData > -1 && PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
            if (strumNote.texture.contains('pixelUI/') || PlayState.isPixelStage) {
                pixelShader = new PixelSplashShaderRef(true);
                shader = pixelShader.shader;
                pixelShader.copyValues(rgbShader.parent);
                if (!rgbEnabled) pixelShader.shader.mult.value = [0];
            }
    
            if(lastAnim != null) {animation.play(lastAnim, true);}

            if (Paths.fileExists('images/' + texture + '.txt', TEXT, true, library)) {
                animOffsets = getOffsetsFromFile(texture, library);
            }

            alpha = ClientPrefs.data.splashAlpha;
        }
    }
}