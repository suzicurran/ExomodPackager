![exomodpackager](https://user-images.githubusercontent.com/8042502/191385388-e739fd91-eec4-44f5-9073-83becf0b5384.png)


# ExomodPackager

## About The Project

ExomodPackager is a tool for modding [I Was a Teenage Exocolonist](http://exocolonist.com/). It supports creation and distribution of changes to the game's .exo files via lightweight patch-based "exomods" without distribution of the game's internal code. ExomodPackager features persistent user settings, safety checks to ensure exomod and game version matching, and more.

## Requirements

- Windows 10+

## Installation

Download the latest version from [Releases](https://github.com/suzicurran/ExomodPackager/releases) and unzip the contents.

## Usage

1. Remember to back up your save data, usually found in /Documents/Exocolonist, before starting. ExomodPackager shouldn't make changes to your local game files, but better safe than sorry.

2. Prepare a "clean" copy of the game's Story files. If you want to use your own install of I Was a Teenage Colonist for this, you can do so by right-clicking the game in your Steam library, selecting Properties, navigating to "Local Files" and then selecting "Verify integrity of game files..."

3. Prepare a copy of the game's story files with your changes included. As a reminder, ExomodPackager will only pick up changes made to .exo files.

4. Inside the ExomodPackager folder, double-click `ExomodPackager.bat` and follow the prompts provided. You will need to provide a path to both sets of game files, information about the mod you're creating, and the name you want to publish your mod under.

5. When ExomodLoader confirms that your mod has created, you're done! You will have a new "outputMod" file in the ExomodPackager directory. Share it with your friends. (Recommended: testing it does what you expect with https://github.com/suzicurran/ExomodLoader first.)

## Roadmap

See the [open issues](https://github.com/suzicurran/exomodpackager/issues) for a list of proposed features (and known issues).

## License

Distributed under the `GPL v2` License. See [LICENSE](https://github.com/suzicurran/exomodpackager/blob/main/LICENSE) for more information.
