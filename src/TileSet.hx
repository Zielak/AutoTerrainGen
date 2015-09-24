import luxe.Sprite;
import phoenix.Texture;

import snow.api.buffers.Uint8Array;


class TileSet {

    public var texture:Texture;

    public var id:String;

    public var preview:Sprite;

    public var tiles:Array<Tile>;

    public function new( t:Texture )
    {
        id = t.id;

        texture = t;

        tiles = new Array<Tile>();

        prepare_tiles();
    }

    function prepare_tiles() {

        var x = Main.tile_size;

        //  o
        add_tile(0,0, Tile.T3);
        add_tile(x,0, Tile.T4);
        add_tile(0,x, Tile.T2);
        add_tile(x,x, Tile.T1);

        // <O>
        add_tile(0,2*x, Tile.T1 & Tile.T2 & Tile.T4);
        add_tile(x,2*x, Tile.T1 & Tile.T2 & Tile.T3);
        add_tile(0,3*x, Tile.T1 & Tile.T3 & Tile.T4);
        add_tile(x,3*x, Tile.T2 & Tile.T3 & Tile.T4);

        //   \ /
        add_tile(2*x,0, Tile.T1 & Tile.T3);
        add_tile(3*x,0, Tile.T2 & Tile.T4);

        //   <|  |>
        add_tile(2*x,x, Tile.T2 & Tile.T3);
        add_tile(3*x,x, Tile.T1 & Tile.T4);

        // ***  ___
        add_tile(2*x,2*x, Tile.T1 & Tile.T2);
        add_tile(3*x,2*x, Tile.T3 & Tile.T4);

        // [] full
        add_tile(2*x,3*x, Tile.T1 & Tile.T2 & Tile.T3 & Tile.T4);

    }

    function add_tile(x:Int, y:Int, flag:Int) {

        var pixels:Uint8Array = new Uint8Array();

        texture.fetch( pixels, x, y, Main.tile_size, Main.tile_size);

        tiles.push( new Tile(pixels, flag) );
    }

}