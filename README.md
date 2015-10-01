# Auto Terrain Generator

> Create terrains for Tiled editor quicker

## Usage

Use this tool to combine your tilesets into one terrain and paint quicker "landscape" in Tiled editor.

### 1. Prepare your tilesets

Each tileset should containt every possible tile combination. Use below template to create your own. Only 15 tiles are used, the last one is ignored.

I've tested this tool for generating terrain of 2, 3 and 4 tilesets. Adding more would probably cause longer generation time, and also I'm not sure how would Tiled react to that.

![Template tileset](https://github.com/Zielak/AutoTerrainGen/usage1.gif "template tileset")

### 2. Set correct tile size

Default is 16px x 16px. Change it in "Configurate" window if you're using different tile size. Width and height must be equal, eg. 32px x 32px.

### 3. Load up all your tilesets

Put all your tilesets into `input` folder, type your filename (with an extension!) and hit `LOAD`. Your tileset should appear in the list below.

Here you can:

- change name of the layer - this will appear in Tiled Terrains window
- change order - bottom layers will be rendered on top of all the other tilesets. Reverse-photoshop style :)
- remove tileset
- click tileset preview to see how the generator split each tile in "Tileset Preview" window

![Load tileset](https://github.com/Zielak/AutoTerrainGen/usage2.png "Load tileset")

### 4. Hit GENERATE!

The terrain will be available to preview in the bottom part of window.

### 5. Export bitmap and TSX file

At the bottom you'll find:

- "Export Bitmap" - save terrain PNG file in `output/` folder
- "Export TSX" - save .tsx file for Tiled in the same folder 

## Work in Tiled

To use your new terrain you have to open new map, go to menu and hit "Map" -> "Add external tileset". Navigate to generator's `output/` folder and choose `output.tsx` file.

# Happy designing!

----

This tool was created using:

- [luxe engine](http://luxeengine.com/docs/) - *luxe is a free, open source cross platform rapid development haxe based game engine for deploying games on Mac, Windows, Linux, Android, iOS and WebGL.*
- [mint](http://snowkit.github.io/mint/) - *mint is minimal, renderer agnostic ui library for Haxe.*
- [format](https://github.com/HaxeFoundation/format) - *The format library contains support for different file-formats for the Haxe programming language.*

----
