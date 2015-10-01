import luxe.Sprite;
import phoenix.Texture;
import luxe.Color;
import snow.api.buffers.Uint8Array;
import Xml;

class Generator {

    public static inline var T1:Hex = 0x0001;
    public static inline var T2:Hex = 0x0010;
    public static inline var T3:Hex = 0x0100;
    public static inline var T4:Hex = 0x1000;
    public static inline var WHOLE:Hex = 0x1111;

    // How much tiles have we generated?
    // Could use output_tiles.length...
    var tile_count:Int;

    //
    var tilesets:Array<TileSet>;

    // Each tile is stored here after generating. Use as source.
    var output_tiles:Array<Tile>;

    // 
    public var output:Texture;

    // TSX for the Tiled. Rebuilt after each output generation
    public var tsx:Xml;

    //
    public var output_pixels:Uint8Array;

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
           Luxe.events.fire('log.add', 'No work needed to do. Add at least one more tileset.');
        }
        // Max 2 types +void on one tile (T+2)
        if(tilesets.length >= 2){

            for(i in 0...tilesets.length){
                main(i);
            }

        }


        apply_output();

        rebuild_tsx();

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
        tile.add_ontop(_pixels, layer, _flag);
    }

    function main_pieces(_flag:Int = 0){
        if(_flag == 0) _flag = piece_main;
        _pixels = tilesets[_main].get(_flag);
        tile.add_ontop(_pixels, _main, _flag);
    }

    // Puts all the pieces together in one tile
    // used in "max 2 different tiles"
    function add_pieces_2(i:Int){

        tile = new Tile();

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

        try_to_add( tile );
        
    }


    // Puts all the pieces together in one tile
    // used in "max 3 different tiles"
    function add_pieces_3(i:Int, j:Int, ?k:Int){

        // trace('add_pieces_3( ${i}, ${j}, ${k} ) | _main = ${_main}');

        var _ordered:Array<LayerFlag> = new Array<LayerFlag>();

        _ordered[0] = {layer: _main, flag: piece_main};
        _ordered[1] = {layer: i, flag: get_nth_piece_flag(piece_gen, 0)};
        _ordered[2] = {layer: j, flag: get_nth_piece_flag(piece_gen, 1)};
        if( k != null ) _ordered[3] = {layer: k, flag: get_nth_piece_flag(piece_gen, 2)};

        _ordered.sort(function(a:LayerFlag,b:LayerFlag):Int {
            if (a.layer == b.layer) return 0;
            if (a.layer > b.layer) return 1;
            else return -1;
        });

        // Lower layers should also have pieces
        // of the higher layers
        if( k == null ){
            _ordered[0].flag = _ordered[0].flag | _ordered[1].flag | _ordered[2].flag;
            _ordered[1].flag = _ordered[1].flag | _ordered[2].flag;
        }else{
            _ordered[0].flag = _ordered[0].flag | _ordered[1].flag | _ordered[2].flag | _ordered[3].flag;
            _ordered[1].flag = _ordered[1].flag | _ordered[2].flag | _ordered[3].flag;
            _ordered[2].flag = _ordered[2].flag | _ordered[3].flag;
        }
        


        // Add combinations
        tile = new Tile();

        for(n in 0..._ordered.length){
            
            get_pieces(_ordered[n].layer, _ordered[n].flag);

        }
        
        try_to_add( tile );

        // trace('DONE');

    }

    // 3 different tiles in one (main and 2 other)
    // Ones and Twos. Threes won't fit 4th different tile.
    // three_others? is ther only one main piece here?
    function walk_tilesets_3(?three_others:Bool = false){

        var go_i:Int;
        var go_j:Int;
        var go_k:Int;

        for(i in 0...tilesets.length) {

            for(j in 0...tilesets.length) {

                if(!three_others){
                    // There are only 2 other pieces
                    go_j = j;
                    go_i = i;

                    // If one of those is same as MAIN,
                    // then make it draw Void
                    if(_main == i) go_i = -1;
                    if(_main == j) go_j = -1;

                    // Can't be the same, we're drawing
                    // only different pieces here
                    if(go_i == go_j) continue;

                    add_pieces_3(go_i, go_j);

                }else{
                    // There are 3 other pieces!
                    for(k in 0...tilesets.length) {
                        go_j = j;
                        go_i = i;
                        go_k = k;

                        // If one of those is same as MAIN,
                        // then make it draw Void
                        if(_main == i) go_i = -1;
                        if(_main == j) go_j = -1;
                        if(_main == k) go_k = -1;

                        // Can't be the same, we're drawing
                        // only different pieces here
                        if(go_i == go_j || go_i == go_k || go_j == go_k) continue;

                        add_pieces_3(go_i, go_j, go_k);

                    }
                }

            }
        }

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

        /**
         * ==========================================================
         *          ORIGINAL           #################### M + 0 ###
         * ==========================================================
         */
        
        for(i in 0...tilesets.length) {

            var _ts = tilesets[i];

            for(_t in _ts.tiles) {

                // set pieces
                _t.pieces[0] = (0x0001 & _t.flag > 0) ? i : -1;
                _t.pieces[1] = (0x0010 & _t.flag > 0) ? i : -1;
                _t.pieces[2] = (0x0100 & _t.flag > 0) ? i : -1;
                _t.pieces[3] = (0x1000 & _t.flag > 0) ? i : -1;

                tile = new Tile();

                main_pieces(_t.flag);

                try_to_add( tile );

            }

        }


        /**
         * ==========================================================
         *      2 different pieces     #################### M + 1 ###
         * ==========================================================
         */

        
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

        


        /**
         * ==========================================================
         *      3 different pieces     ################## M + 2 #####
         * ==========================================================
         */
        

        
        // Ones (one piece of the main tile)

        
        // |---+---|
        // | X |   |
        // |---+---|
        // |   |   |
        // |---+---|
        piece_gen = T2 | T3 | T4;
        piece_main = T1;
        walk_tilesets_3(true);

        
        // |---+---|
        // |   | X |
        // |---+---|
        // |   |   |
        // |---+---|
        piece_gen = T1 | T3 | T4;
        piece_main = T2;
        walk_tilesets_3(true);

        
        // |---+---|
        // |   |   |
        // |---+---|
        // |   | X |
        // |---+---|
        piece_gen = T1 | T2 | T4;
        piece_main = T3;
        walk_tilesets_3(true);

        
        // |---+---|
        // |   |   |
        // |---+---|
        // | X |   |
        // |---+---|
        piece_gen = T1 | T2 | T3;
        piece_main = T4;
        walk_tilesets_3(true);


        // Twos (2 pieces of the main tile)

        //
        // |---+---|
        // | X |   |
        // |---+---|
        // |   | X |
        // |---+---|
        piece_gen = T2 | T4;
        piece_main = T1 | T3;
        walk_tilesets_3();
        
        
        // |---+---|
        // |   | X |
        // |---+---|
        // | X |   |
        // |---+---|
        piece_gen = T1 | T3;
        piece_main = T2 | T4;
        walk_tilesets_3();
        
        
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
        piece_gen = T1 | T4;
        piece_main = T2 | T3;
        walk_tilesets_3();
        
        
        // |---+---|
        // | X | X |
        // |---+---|
        // |   |   |
        // |---+---|
        piece_gen = T3 | T4;
        piece_main = T1 | T2;
        walk_tilesets_3();
        
        
        // |---+---|
        // |   |   |
        // |---+---|
        // | X | X |
        // |---+---|
        piece_gen = T1 | T2;
        piece_main = T3 | T4;
        walk_tilesets_3();
        
        /**/
    }


    public function calculate_tiles() {

        var l:Int = tilesets.length;

        if(l == 1){

            tile_count = tilesets[0].tiles.length;
        }

        if(l >= 2){

            tile_count = 0;

            // Original

            tile_count = (tilesets.length+1) * 15;

            // M + 1

            // 4 ones (has 3 other pieces)
            tile_count += 4*(l*l*l);

            // 6 twos (has 2 other pieces)
            tile_count += 6*(l*l);

            // 4 threes (has 1 other piece)
            tile_count += 4*(l);

            // M + 2

            // 6 twos (has 2 main pieces)
            tile_count += 6*(l*l*l);

            // I don't even know
            tile_count += 4*( l );

        }

        Luxe.events.fire('config_text.update', '(Wrongly) predicting ${tile_count} tiles...');

    }

    function prepare_output() {

        output_tiles = new Array<Tile>();

    }

    function apply_output() {

        w = Math.ceil( Math.sqrt(output_tiles.length) ) * Main.tile_size;
        h = w;

        var x:Int = 0;
        var y:Int = 0;
        var x2:Int = 0;
        var y2:Int = 0;

        Luxe.events.fire('log.add', 'Output dimensions: ${w}px x ${h}px');
        Luxe.events.fire('log.add', 'Got ${output_tiles.length} tiles in output.');

        var _pixels:Uint8Array = new Uint8Array( w*h*4 );

        // Get each tile
        for(_t in output_tiles){

            x2 = 0;
            y2 = 0;

            if(_t == null) continue;

            // trace('_t: ${_t}');
            // trace('_t.pixels: ${_t.pixels}');
            // trace('_t.pixels.length: ${_t.pixels.length}');

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
        
        // Create new 'output' texture if it's not in resources yet
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

            // Already have 'output' texture in resources, go on.

            output.width = output.width_actual = w;
            output.height = output.height_actual = h;
            output.submit(_pixels);
        }

        // place the pixels into output_pixels
        // Gotta swap reds with blues first

        inline function bset(p,v) {
            return _pixels[p] = v;
        }

        var p:Int = 0;
        for( i in 0..._pixels.length >> 2 ) {
            var r = _pixels[p];
            var g = _pixels[p + 1];
            var b = _pixels[p + 2];
            var a = _pixels[p + 3];
            bset(p++, b);
            p++;// bset(p++, g);
            bset(p++, r);
            p++;// bset(p++, a);
        }

        output_pixels = _pixels;
    }

    /**
     * Loops through every tile in output_tiles
     * if the given tile already exists - do nothing
     * add new tile only if it's unique
     * @param  _t New generated
     * @return    true if new tile was added to output
     */
    function try_to_add( _t:Tile ):Bool{

        var newtile:String = _t.toString();

        for( outile in output_tiles ){

            if(outile == null) continue;
#if debug
            // trace('outile: ${outile}');
            // trace('outile.toString(): ${outile.toString()}');
            // trace('newtile: ${newtile}');
#end
            if( outile.toString() == newtile ){
#if debug
                // trace('given tile already exists! ignoring');
#end
                return false;
            }

        }

        output_tiles.push( tile );
        return true;

    }

    function find_tile_by_flag(s:String):Int {

        for( i in 0...output_tiles.length ){
            if(output_tiles[i].toString() == s ) return i;
        }
        return -1;
    }

    /**
     * Rebuilds whole TSX XML object. Use after generating output
     */
    function rebuild_tsx() {

        trace('<tileset name="tileset" tilewidth="${Main.tile_size}" tileheight="${Main.tile_size}" tilecount="${output_tiles.length}"></tileset>');

        tsx = Xml.createDocument();
        tsx.addChild( Xml.parse('<?xml version="1.0" encoding="UTF-8"?>') );

        var _tileset = Xml.createElement('tileset');
        _tileset.set('name', 'tileset');
        _tileset.set('tilewidth', '${Main.tile_size}');
        _tileset.set('tileheight', '${Main.tile_size}');
        _tileset.set('tilecount', '${output_tiles.length}');

        // Image
        // 
        _tileset.addChild( Xml.parse('<image source="output.png" width="${w}" height="${h}"/>') );


        // terraintypes
        // 
        var _terrains = Xml.createElement('terraintypes');

        for(i in 0...tilesets.length){

            var _tr:TileSet = tilesets[i];
            var _terrain = Xml.createElement('terrain');
            _terrain.set('name', _tr.name);
            var s:String = ''+i+i+i+i;
            _terrain.set('tile', '${find_tile_by_flag( s )}');

            _terrains.addChild(_terrain);
        }
        _tileset.addChild(_terrains);


        // Tiles
        // 
        var _tx:Xml;
        var _tile:Tile;
        var str:String = '';
        for(i in 0...output_tiles.length){

            _tx = Xml.createElement('tile');
            _tile = output_tiles[i];

            if(_tile == null) continue;

            _tx.set('id', Std.string(i) );

            // Tiled order of "pieces"
            // |---+---|
            // | 1 | 2 |
            // |---+---|
            // | 3 | 4 |
            // |---+---|
            // Gotta change that
            str = '';
            str += (_tile.pieces[0] >= 0) ? Std.string(_tile.pieces[0]) : '';
            str += ',';
            str += (_tile.pieces[1] >= 0) ? Std.string(_tile.pieces[1]) : '';
            str += ',';
            str += (_tile.pieces[3] >= 0) ? Std.string(_tile.pieces[3]) : '';
            str += ',';
            str += (_tile.pieces[2] >= 0) ? Std.string(_tile.pieces[2]) : '';

            _tx.set('terrain', str);

            _tileset.addChild(_tx);
        }

        tsx.addChild( _tileset );
        

    }




}

typedef LayerFlag = {

    var layer:Int;
    var flag:Int;
}
