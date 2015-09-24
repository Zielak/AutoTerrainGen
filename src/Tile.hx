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

    public var texture:Texture;

    public var pixels:Uint8Array;
    public var flag:Hex;

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


}