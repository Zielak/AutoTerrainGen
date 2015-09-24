import luxe.Sprite;
import phoenix.Texture;
import luxe.Color;
import snow.api.buffers.Uint8Array;


class Generator {

    var tile_count:Int;
    var out_width:Int;
    var out_height:Int;

    var pixelsData2D:Array<Array<Color>>;
    var pixelsInt:Array<Int>;
    var pixelsIntSplit:Array<Int>;
    var pixelsUInt8:Uint8Array;

    var tilesets:Array<TileSet>;
    var output:Texture;

    public function new() {

        var pixelsData2D = new Array<Array<Color>>( );
        var pixelsInt = new Array<Int>( );
        var pixelsIntSplit = new Array<Int>( );
        var pixelsUInt8 = new Uint8Array();

        output = new Texture({
            id: 'output',
            filter_mag: phoenix.FilterType.nearest,
            filter_min: phoenix.FilterType.nearest,
        }); 

    }

    public function update_tilesets( _ts:Array<TileSet> ) {

        tilesets = _ts;
        calculate_tiles();

    }

    public function generate() {

        // Has only combination of tileset with void
        // Thats actually the same as input...
        if(tilesets.length == 1){
           // stage_1();
           trace('no work needed to do');
        }
        // Max 2 types +void on one tile (T+2)
        if(tilesets.length == 2){
            stage_2();
        }

    }


    function stage_2() {

        prepare_output();

        // Which pieces to generate?
        var p1:Int;
        var p2:Int;
        var p3:Int;

        // Temp pixels array to store pixels of tiles
        var _pixels:Uint8Array = new Uint8Array(Main.tile_size*Main.tile_size*4);

        var tile:Tile;

        // Threes (3 pieces of the same tile)

        /**
         * |---+---|
         * |   | X |
         * |---+---|
         * | X | X |
         * |---+---|
         */
        
        p1 = Tile.T1;

        for(i in 0...tilesets.length) {

            // get missing piece
            tile = new Tile();

            _pixels = tilesets[i].get(p1);
            // _pixels.byteOffset = 
            // output.submit()

        }
        

        /**
         * |---+---|
         * | X |   |
         * |---+---|
         * | X | X |
         * |---+---|
         */
        
        p1 = Tile.T2;

        /**
         * |---+---|
         * | x | X |
         * |---+---|
         * | X |   |
         * |---+---|
         */
        
        p1 = Tile.T3;

        /**
         * |---+---|
         * | X | X |
         * |---+---|
         * |   | X |
         * |---+---|
         */
        
        p1 = Tile.T4;

    }


    public function calculate_tiles() {

        var l:Int = tilesets.length;

        if(l == 1){

            tile_count = tilesets[0].tiles.length;
        }

        if(l >= 2){

            tile_count = 0;

            // 4 ones (has 3 other tiles)
            tile_count += 4*(l*l*l);

            // 6 twos (has 2 other tiles)
            tile_count += 6*(l*l);

            // 4 threes (has 1 other tile)
            tile_count += 4*(l);

        }

        Luxe.events.fire('config_text.update', '${tile_count} tiles.');

    }

    function prepare_output() {

        

    }



}