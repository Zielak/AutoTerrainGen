import luxe.Sprite;
import phoenix.Texture;
import luxe.Color;
import snow.api.buffers.Uint8Array;


class Generator {

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
                main_3(i);
            }

        }


        apply_output();

        Luxe.events.fire('generator.done');

    }

    /**
     * All combinations with 3 pieces of main thing
     */
    function main_3( main:Int ) {

        // Which pieces to generate?
        var p:Int;

        // Which pieces are from main tileset?
        var pm:Int;

        // Temp pixels array to store pixels of tiles
        var _pixels:Uint8Array = new Uint8Array(Main.tile_size*Main.tile_size*4);

        var tile:Tile;

        inline function main_pieces(_flag:Int = 0){
            if(_flag == 0) _flag = pm;
            _pixels = tilesets[main].get(_flag);
            tile.add_ontop(_pixels);
        }
        inline function other_pieces(i:Int, ?_flag:Int = 0){
            if(_flag == 0) _flag = p;
            _pixels = tilesets[i].get(_flag);
            tile.add_ontop(_pixels);
        }
        // Puts all the pieces together in one tile
        inline function add_pieces(i:Int){

            if(i > main){
                main_pieces(Tile.WHOLE);
                other_pieces(i);
            }else if(i < main){
                other_pieces(i);
                main_pieces();
            }else{
                // Void
                main_pieces();
            }
        }
        // 
        inline function walk_tilesets(){

            for(i in 0...tilesets.length) {

                tile = new Tile();

                add_pieces(i);

                output_tiles.push( tile );
            }
            
        }


        // Threes (3 pieces of the same tile)

        /**
         * |---+---|
         * |   | X |
         * |---+---|
         * | X | X |
         * |---+---|
         */
        
        p = Tile.T1;
        pm = Tile.T2 | Tile.T3 | Tile.T4;
        walk_tilesets();

        /**
         * |---+---|
         * | X |   |
         * |---+---|
         * | X | X |
         * |---+---|
         */
        
        p = Tile.T2;
        pm = Tile.T1 | Tile.T3 | Tile.T4;
        walk_tilesets();

        /**
         * |---+---|
         * | X | X |
         * |---+---|
         * | X |   |
         * |---+---|
         */
        
        p = Tile.T3;
        pm = Tile.T1 | Tile.T2 | Tile.T4;
        walk_tilesets();

        /**
         * |---+---|
         * | X | X |
         * |---+---|
         * |   | X |
         * |---+---|
         */
        
        p = Tile.T4;
        pm = Tile.T1 | Tile.T2 | Tile.T3;
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

        Luxe.events.fire('config_text.update', '${tile_count} tiles.');

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