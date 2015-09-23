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

    public static function generate( tilesets:Array<TileSet> ) {

        if(tilesets.length == 1){
            stage_1();
        }
        if(tilesets.length == 2){
            stage_2();
        }
        if(tilesets.length == 3){
            stage_3();
        }
        if(tilesets.length == 4){
            stage_4();
        }

    }



}