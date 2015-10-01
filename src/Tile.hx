import luxe.Resources;
import phoenix.Texture;

import snow.api.buffers.Uint8Array;


class Tile {

    /**
     * |---+---|
     * | 1 | 2 |
     * |---+---|
     * | 4 | 3 |
     * |---+---|
     */

    public static inline var T1:Hex = 0x0001;
    public static inline var T2:Hex = 0x0010;
    public static inline var T3:Hex = 0x0100;
    public static inline var T4:Hex = 0x1000;
    public static inline var WHOLE:Hex = 0x1111;

    public var texture:Texture;

    public var pixels:Uint8Array;
    public var flag:Hex;

    // What tileset is placed in which piece?
    public var pieces:Array<Int>;

    var foreign_id:String;
    public var id:String = '';

    public function new(?p:Uint8Array, ?f:Hex = 0x1111, ?_id:String){

        
        if(_id != null) foreign_id = _id;

        // Is it part of tileset or tile ready for the output?
        flag = f;

        // Get pixels straight from above or prepare empty place
        if(p != null){
            pixels = p;
            prepare_texture();
        }else{
            pixels = new Uint8Array(Main.tile_size*Main.tile_size*4);
        }

        pieces = new Array<Int>();
        pieces[0] = -1;
        pieces[1] = -1;
        pieces[2] = -1;
        pieces[3] = -1;

    }

    /**
     * Not all tiles are used to be visible in UI.
     * Use this to change this one in usable Texture
     * @return ID of texture to get
     */
    function prepare_texture(){

        if(texture != null){
            return;
        }

        id = '${foreign_id}_${flag}';

        texture = new Texture({
            pixels: pixels,
            id: id,
            width: Main.tile_size,
            height: Main.tile_size,
            filter_mag: phoenix.FilterType.nearest,
            filter_min: phoenix.FilterType.nearest,
        });

        Luxe.resources.add(texture);

    }


    public function add_ontop( _pixels:Uint8Array, _layer:Int, _flag:Int ){

        if(texture != null) return;

        var color:C = {r:0, g:0, b:0, a:0};
        var n = 0;

        while( n < _pixels.length ){

            // get pixel
            color.r = _pixels[n];
            color.g = _pixels[n+1];
            color.b = _pixels[n+2];
            color.a = _pixels[n+3];

            // do nothing if transparent
            if(color.a > 0){
                // trace('gonna draw: ${color}');
                pixels[n] = color.r;
                pixels[n+1] = color.g;
                pixels[n+2] = color.b;
                pixels[n+3] = color.a;
            }

            n += 4;

        }

        // Now keep info about this action
        var _flags = [0x0001,0x0010,0x0100,0x1000];
        for(i in 0..._flags.length){
            if(_flags[i] & _flag > 0) pieces[i] = _layer;
        }
    }

    /**
     * Gives string for comparison of the same tiles
     * @return 
     */
    public function toString():String{
        var s:String = '';
        for(i in pieces){
            if(i == -1) s += 'V';
            else s += i;
        }
        return s;
    }

}

typedef C = {
    var a:Int;
    var r:Int;
    var g:Int;
    var b:Int;
}
