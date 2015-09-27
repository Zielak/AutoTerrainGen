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

    public function new() {


        // output = new Texture({
        //     id: 'output',
        //     filter_mag: phoenix.FilterType.nearest,
        //     filter_min: phoenix.FilterType.nearest,
        // });        

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

    function main( main:Int ) {

        // Which pieces to generate?
        var piece_gen:Int;

        // Which pieces are from main tileset?
        var piece_main:Int;

        // Temp pixels array to store pixels of tiles
        var _pixels:Uint8Array = new Uint8Array(Main.tile_size*Main.tile_size*4);

        var tile:Tile;





        inline function main_pieces(_flag:Int = 0){
            if(_flag == 0) _flag = piece_main;
            _pixels = tilesets[main].get(_flag);
            tile.add_ontop(_pixels);
        }

        inline function other_pieces(i:Int, ?_flag:Int = 0){
            if(_flag == 0) _flag = piece_gen;
            _pixels = tilesets[i].get(_flag);
            tile.add_ontop(_pixels);
        }

        // Puts all the pieces together in one tile
        // used in "max 2 different tiles"
        inline function add_pieces_2(i:Int){

            if(i > main){
                main_pieces(Tile.WHOLE);
                other_pieces(i);
            }else if(i < main){
                other_pieces(i, Tile.WHOLE);
                main_pieces();
            }else{
                // Void
                main_pieces();
            }
        }

        // 
        inline function walk_tilesets(){

            // 2 different tiles
            for(i in 0...tilesets.length) {

                tile = new Tile();
                add_pieces_2(i);
                output_tiles.push( tile );
            }

            // 3 different tiles in one
            // Ones and Twos. Threes won't fit 4th different tile.
            
            // TODO

        }




        // Threes (3 pieces of the main tile)

        /**
         * |---+---|
         * |   | X |
         * |---+---|
         * | X | X |
         * |---+---|
         */
        
        piece_gen = T1;
        piece_main = T2 | T3 | T4;
        walk_tilesets();

        /**
         * |---+---|
         * | X |   |
         * |---+---|
         * | X | X |
         * |---+---|
         */
        
        piece_gen = T2;
        piece_main = T1 | T3 | T4;
        walk_tilesets();

        /**
         * |---+---|
         * | X | X |
         * |---+---|
         * | X |   |
         * |---+---|
         */
        
        piece_gen = T3;
        piece_main = T1 | T2 | T4;
        walk_tilesets();

        /**
         * |---+---|
         * | X | X |
         * |---+---|
         * |   | X |
         * |---+---|
         */
        
        piece_gen = T4;
        piece_main = T1 | T2 | T3;
        walk_tilesets();




        // Twos (2 pieces of the main tile)

        /**
         * |---+---|
         * | X |   |
         * |---+---|
         * |   | X |
         * |---+---|
         */
        piece_gen = T2 | T4;
        piece_main = T1 | T3;
        walk_tilesets();
        
        /**
         * |---+---|
         * |   | X |
         * |---+---|
         * | X |   |
         * |---+---|
         */
        piece_gen = T1 | T3;
        piece_main = T2 | T4;
        walk_tilesets();
        
        /**
         * |---+---|
         * | X |   |
         * |---+---|
         * | X |   |
         * |---+---|
         */
        piece_gen = T2 | T3;
        piece_main = T1 | T4;
        walk_tilesets();
        
        /**
         * |---+---|
         * |   | X |
         * |---+---|
         * |   | X |
         * |---+---|
         */
        piece_gen = T1 | T4;
        piece_main = T2 | T3;
        walk_tilesets();
        
        /**
         * |---+---|
         * | X | X |
         * |---+---|
         * |   |   |
         * |---+---|
         */
        piece_gen = T3 | T4;
        piece_main = T1 | T2;
        walk_tilesets();
        
        /**
         * |---+---|
         * |   |   |
         * |---+---|
         * | X | X |
         * |---+---|
         */
        piece_gen = T1 | T2;
        piece_main = T3 | T4;
        walk_tilesets();


        // Ones (one piece of the main tile)

        /**
         * |---+---|
         * | X |   |
         * |---+---|
         * |   |   |
         * |---+---|
         */
        piece_gen = T2 | T3 | T4;
        piece_main = T1;
        walk_tilesets();

        /**
         * |---+---|
         * |   | X |
         * |---+---|
         * |   |   |
         * |---+---|
         */
        piece_gen = T1 | T3 | T4;
        piece_main = T2;
        walk_tilesets();

        /**
         * |---+---|
         * |   |   |
         * |---+---|
         * |   | X |
         * |---+---|
         */
        piece_gen = T1 | T2 | T4;
        piece_main = T3;
        walk_tilesets();

        /**
         * |---+---|
         * |   |   |
         * |---+---|
         * | X |   |
         * |---+---|
         */
        piece_gen = T1 | T2 | T3;
        piece_main = T4;
        walk_tilesets();
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