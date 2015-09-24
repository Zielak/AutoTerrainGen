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

    public static inline var T1:Int = 0x0001;
    public static inline var T2:Int = 0x0010;
    public static inline var T3:Int = 0x0100;
    public static inline var T4:Int = 0x1000;

    var texture:Texture;

    public var pixels:Uint8Array;
    public var flag:Int;

    var foreign_id:String;
    public var id:String;

    public function new(p:Uint8Array, f:Int, _id:String){

        pixels = p;
        flag = f;

        foreign_id = _id;
        id = '${foreign_id}_${flag}';

        // Luxe.resources.add( new luxe.resource.Resource.Resource({
        //     resource_type: ResourceType.texture,
        //     id: id,
        // }) );

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

    public function get_corner(){

    }

}