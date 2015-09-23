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

    public function new(p:Uint8Array, f:Int){

        pixels = p;
        flag = f;

    }

    public function get_corner

}