import luxe.Sprite;
import phoenix.Texture;
import luxe.Color;
import snow.api.buffers.Uint8Array;


class Generator {

    var output:Texture;

    var pixelsData2D:Array<Array<Color>>;
    var pixelsInt:Array<Int>;
    var pixelsIntSplit:Array<Int>;
    var pixelsUInt8:Uint8Array;

    var source:Array<TileSet>;

    public function new() {

        var pixelsData2D = new Array<Array<Color>>( );
        var pixelsInt = new Array<Int>( );
        var pixelsIntSplit = new Array<Int>( );
        var pixelsUInt8 = new Uint8Array();

    }

    public function generate( tilesets:Array<TileSet> ) {

        // Has only combination of tileset with void
        // Thats actually the same as input...
        if(tilesets.length == 1){
           // stage_1();
           trace('no work needed to do');
        }
        // Max 2 types +void on one tile
        if(tilesets.length == 2){
            stage_2();
        }

    }


    function stage_2() {



    }



}