import luxe.Sprite;
import phoenix.Texture;
import luxe.Color;
import snow.api.buffers.Uint8Array;


class Generator {

    public static inline var T1:Hex = 0x0001;
    public static inline var T2:Hex = 0x0010;
    public static inline var T3:Hex = 0x0100;
    public static inline var T4:Hex = 0x1000;
    public static inline var WHOLE:Hex = 0x1111;

    var tile_count:Int;
    var out_width:Int;
    var out_height:Int;

    var tilesets:Array<TileSet>;

    var output_tiles:Array<Tile>;
    var output_pixels:Uint8Array;
    public var output:Texture;

    public var w:Int = 0;
    public var h:Int = 0;


    // Which pieces to generate right now?
    var piece_gen:Int;

    // Which pieces are from main tileset right now?
    var piece_main:Int;

    // Temp tile
    var tile:Tile;

    // Temp pixels array to store pixels of tiles
    var _pixels:Uint8Array;

    // Current MAIN tileset
    var _main:Int;

    public function new() {

    }

    public function update_tilesets( _ts:Array<TileSet> ) {

        tilesets = _ts;
        calculate_tiles();

    }

    public function generate() {

        prepare_output();

        // Has only combination of tileset with void
        // Thats actually the same as input...
        if(tilesets.length == 1){
           // stage_1();
           trace('no work needed to do');
        }
        // Max 2 types +void on one tile (T+2)
        if(tilesets.length >= 2){

            for(i in 0...tilesets.length){
                main(i);
            }

        }


        apply_output();

        Luxe.events.fire('generator.done');

    }

    // Returns nth empty piece (0) in piece_gen and returns its flag (one piece only).
    function get_nth_piece_flag(flag:Int, i:Int):Int{

        var _pieces:Array<Bool> = new Array<Bool>();

        var _count:Int = i;

        _pieces[0] = (flag & 0x0001 > 0);
        _pieces[1] = (flag & 0x0010 > 0);
        _pieces[2] = (flag & 0x0100 > 0);
        _pieces[3] = (flag & 0x1000 > 0);

        for(j in 0..._pieces.length){
            
            if(_pieces[j]){
                _count--;
                if(_count >= 0) continue;

                return [0x0001, 0x0010, 0x0100, 0x1000][j];
            }
             
        }
        return 0x0000;
    }

    // Adds pieces of given layer on tile
    // if flag is not set, then it's current piece_gen
    function get_pieces(layer:Int, ?_flag:Int = 0){

        // Set default flag
        if(_flag == 0) _flag = piece_gen;

        // Void? nothing to do
        if(layer < 0) return;

        _pixels = tilesets[layer].get(_flag);
        tile.add_ontop(_pixels);
    }

    function main_pieces(_flag:Int = 0){
        if(_flag == 0) _flag = piece_main;
        _pixels = tilesets[_main].get(_flag);
        tile.add_ontop(_pixels);
    }

    // Puts all the pieces together in one tile
    // used in "max 2 different tiles"
    function add_pieces_2(i:Int){

        if(i > _main){
            main_pieces(Tile.WHOLE);
            get_pieces(i);
        }else if(i < _main){
            get_pieces(i, Tile.WHOLE);
            main_pieces();
        }else{
            // Adds Void when other == _main
            main_pieces();
        }
    }


    // Puts all the pieces together in one tile
    // used in "max 3 different tiles"
    function add_pieces_3(i:Int, j:Int){

        trace('add_pieces_3( ${i}, ${j} ) | _main = ${_main}');

        // Don't repeat yourself, you already did that with add_piece_2()
        // 'other' pieces are the same
        if(i == j){
            trace(' - i == j, cancelling');
            return;
        }

        // if i or j are equal to _main treat them as void
        if( i == _main ){
            i = -1;
            trace(' - i set to Void');
        }
        if( j == _main ){
            j = -1;
            trace(' - j set to Void');
        }

        // var _layers:Array<Array<Int>> = [
        //     [_main, i, j],
        //     [_main, j, i],
        //     [i, _main, j],
        //     [j, _main, i],
        //     [i, j, _main],
        //     [j, i, _main],
        // ];

        // Painting order
        var _layers:Array<Int> = [_main, i, j];

        _layers.sort(function(a:Int,b:Int):Int {
            if (a == b) return 0;
            if (a > b) return 1;
            else return -1;
        });

        var _order:Array<Int> = [_main, i, j];

        // var _flags:Array<Array<Int>> = [
        //     [piece_main, get_nth_piece_flag(piece_gen, 0), get_nth_piece_flag(piece_gen, 1)],
        //     [piece_main, get_nth_piece_flag(piece_gen, 0), get_nth_piece_flag(piece_gen, 1)],
        //     [get_nth_piece_flag(piece_gen, 0), piece_main, get_nth_piece_flag(piece_gen, 1)],
        //     [get_nth_piece_flag(piece_gen, 0), piece_main, get_nth_piece_flag(piece_gen, 1)],
        //     [get_nth_piece_flag(piece_gen, 0), get_nth_piece_flag(piece_gen, 1), piece_main],
        //     [get_nth_piece_flag(piece_gen, 0), get_nth_piece_flag(piece_gen, 1), piece_main],
        // ];

        // Add combinations
        // for(x in 0..._flags.length){

        tile = new Tile();

        var _count:Int = 0;

        for(k in 0...3){
            
            if(_layers[k] == _main){
                main_pieces(_layers[k]);
            }else{
                get_pieces(_layers[k], get_nth_piece_flag(piece_gen, _count));
                _count++;
            }

        }
            
                

        output_tiles.push( tile );

        trace('DONE');

        // }

    }

    function main( main:Int ) {

        _main = main;

        _pixels = new Uint8Array(Main.tile_size*Main.tile_size*4);


        // 2 different tiles (main and other)
        inline function walk_tilesets_2(){

            for(i in 0...tilesets.length) {

                add_pieces_2(i);
            }

        }

        // 3 different tiles in one (main and 2 other)
        // Ones and Twos. Threes won't fit 4th different tile.
        inline function walk_tilesets_3(){

            for(i in 0...tilesets.length) {

                for(j in 0...tilesets.length) {

                    add_pieces_3(i, j);

                }
            }

        }


        /**
         * ==========================================================
         *      2 different pieces     ##############################
         * ==========================================================
         */

         /* turning off for testing

        // Threes (3 pieces of the main tile)

        
        // |---+---|
        // |   | X |
        // |---+---|
        // | X | X |
        // |---+---|
        piece_gen = T1;
        piece_main = T2 | T3 | T4;
        walk_tilesets_2();

        
        // |---+---|
        // | X |   |
        // |---+---|
        // | X | X |
        // |---+---|
        piece_gen = T2;
        piece_main = T1 | T3 | T4;
        walk_tilesets_2();

        
        // |---+---|
        // | X | X |
        // |---+---|
        // | X |   |
        // |---+---|
        piece_gen = T3;
        piece_main = T1 | T2 | T4;
        walk_tilesets_2();

        
        // |---+---|
        // | X | X |
        // |---+---|
        // |   | X |
        // |---+---|
        piece_gen = T4;
        piece_main = T1 | T2 | T3;
        walk_tilesets_2();




        // Twos (2 pieces of the main tile)

        
        // |---+---|
        // | X |   |
        // |---+---|
        // |   | X |
        // |---+---|
        piece_gen = T2 | T4;
        piece_main = T1 | T3;
        walk_tilesets_2();
        
        
        // |---+---|
        // |   | X |
        // |---+---|
        // | X |   |
        // |---+---|
        piece_gen = T1 | T3;
        piece_main = T2 | T4;
        walk_tilesets_2();
        
        
        // |---+---|
        // | X |   |
        // |---+---|
        // | X |   |
        // |---+---|
        piece_gen = T2 | T3;
        piece_main = T1 | T4;
        walk_tilesets_2();
        
        
        // |---+---|
        // |   | X |
        // |---+---|
        // |   | X |
        // |---+---|
        piece_gen = T1 | T4;
        piece_main = T2 | T3;
        walk_tilesets_2();
        
        
        // |---+---|
        // | X | X |
        // |---+---|
        // |   |   |
        // |---+---|
        piece_gen = T3 | T4;
        piece_main = T1 | T2;
        walk_tilesets_2();
        
        
        // |---+---|
        // |   |   |
        // |---+---|
        // | X | X |
        // |---+---|
        piece_gen = T1 | T2;
        piece_main = T3 | T4;
        walk_tilesets_2();


        // Ones (one piece of the main tile)

        
        // |---+---|
        // | X |   |
        // |---+---|
        // |   |   |
        // |---+---|
        piece_gen = T2 | T3 | T4;
        piece_main = T1;
        walk_tilesets_2();

        
        // |---+---|
        // |   | X |
        // |---+---|
        // |   |   |
        // |---+---|
        piece_gen = T1 | T3 | T4;
        piece_main = T2;
        walk_tilesets_2();

        
        // |---+---|
        // |   |   |
        // |---+---|
        // |   | X |
        // |---+---|
        piece_gen = T1 | T2 | T4;
        piece_main = T3;
        walk_tilesets_2();

        
        // |---+---|
        // |   |   |
        // |---+---|
        // | X |   |
        // |---+---|
        piece_gen = T1 | T2 | T3;
        piece_main = T4;
        walk_tilesets_2();

        */


        /**
         * ==========================================================
         *      3 different pieces     ##############################
         * ==========================================================
         */
        

        
        // Ones (one piece of the main tile)

        
        // |---+---|
        // | X |   |
        // |---+---|
        // |   |   |
        // |---+---|
        // piece_gen = T2 | T3 | T4;
        // piece_main = T1;
        // walk_tilesets_3();

        
        // |---+---|
        // |   | X |
        // |---+---|
        // |   |   |
        // |---+---|
        // piece_gen = T1 | T3 | T4;
        // piece_main = T2;
        // walk_tilesets_3();

        
        // |---+---|
        // |   |   |
        // |---+---|
        // |   | X |
        // |---+---|
        // piece_gen = T1 | T2 | T4;
        // piece_main = T3;
        // walk_tilesets_3();

        
        // |---+---|
        // |   |   |
        // |---+---|
        // | X |   |
        // |---+---|
        // piece_gen = T1 | T2 | T3;
        // piece_main = T4;
        // walk_tilesets_3();


        // Twos (2 pieces of the main tile)

        
        // |---+---|
        // | X |   |
        // |---+---|
        // |   | X |
        // |---+---|
        // piece_gen = T2 | T4;
        // piece_main = T1 | T3;
        // walk_tilesets_3();
        
        
        // |---+---|
        // |   | X |
        // |---+---|
        // | X |   |
        // |---+---|
        // piece_gen = T1 | T3;
        // piece_main = T2 | T4;
        // walk_tilesets_3();
        
        
        // |---+---|
        // | X |   |
        // |---+---|
        // | X |   |
        // |---+---|
        piece_gen = T2 | T3;
        piece_main = T1 | T4;
        walk_tilesets_3();
        
        
        // |---+---|
        // |   | X |
        // |---+---|
        // |   | X |
        // |---+---|
        // piece_gen = T1 | T4;
        // piece_main = T2 | T3;
        // walk_tilesets_3();
        
        
        // |---+---|
        // | X | X |
        // |---+---|
        // |   |   |
        // |---+---|
        // piece_gen = T3 | T4;
        // piece_main = T1 | T2;
        // walk_tilesets_3();
        
        
        // |---+---|
        // |   |   |
        // |---+---|
        // | X | X |
        // |---+---|
        // piece_gen = T1 | T2;
        // piece_main = T3 | T4;
        // walk_tilesets_3();
        
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

        Luxe.events.fire('config_text.update', 'Predicting ${tile_count} tiles.');

    }

    function prepare_output() {

        output_tiles = new Array<Tile>();

    }

    function apply_output() {

        w = Math.ceil( Math.sqrt(output_tiles.length) ) * Main.tile_size;
        h = w;
        // w = 64;
        // h = 64;
        // Texture size must be square of 2?


        var x:Int = 0;
        var y:Int = 0;
        var x2:Int = 0;
        var y2:Int = 0;

        trace('apply_output: ${w}, ${h}');
        trace('got ${output_tiles.length} tiles in output.');

        var _pixels:Uint8Array = new Uint8Array( w*h*4 );
        var _t:Tile;

        // Get each tile
        for(_t in output_tiles){

            x2 = 0;
            y2 = 0;

            // Draw each pixel
            for(i in 0..._t.pixels.length){

                _pixels[ ( (y+y2)*w*4 ) + x*4 + x2 ] = _t.pixels[i];

                if(x > 2){
                    // trace('x2 = ${x2}');
                    // trace('pixel: ${ ((y+y2)*w*4) + x*4 + x2}');
                }

                x2 ++;

                if(x2 >= Main.tile_size*4){
                    y2 ++;
                    x2 = 0;
                }


            }

            x += Main.tile_size;

            if(x >= w){
                x = 0;
                y += Main.tile_size;
            }

        }
        
        
        if(Luxe.resources.texture('output') == null){

            output = new Texture({
                pixels: _pixels,
                id: 'output',
                width: w,
                height: h,
                filter_mag: phoenix.FilterType.nearest,
                filter_min: phoenix.FilterType.nearest,
            }); 

            Luxe.resources.add(output);

        }else{

            output.width = output.width_actual = w;
            output.height = output.height_actual = h;
            output.submit(_pixels);
        }
    }

}