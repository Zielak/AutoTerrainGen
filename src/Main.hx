
import luxe.Input;

import luxe.Color;
import luxe.Component;
import luxe.options.SpriteOptions;
import luxe.Sprite;
import luxe.Vector;
import luxe.Text;
import phoenix.Texture;


import mint.Control;
import mint.types.Types;
import mint.render.luxe.LuxeMintRender;
import mint.render.luxe.Convert;
import mint.layout.margins.Margins;


class Main extends luxe.Game {

    /**
     * Main rendered sprite, where everything is visible
     */
    public static var sprite:Sprite;

    /**
     * TODO: to change
     */
    public static var tile_size:Int = 16;

    var generator:Generator;

    var tilesets:Array<TileSet>;


    var disp : Text;
    var canvas: mint.Canvas;
    var rendering: LuxeMintRender;
    var layout: Margins;

    var window1:mint.Window;
    var path_input:mint.TextEdit;
    var load_button:mint.Button;
    var generate_button:mint.Button;
    var config_text:mint.Label;
    var tilesets_list:mint.List;

    var window_tileset:mint.Window;
    var tiles_list:mint.List;
    var tileset_title:mint.Label;

    var window_output:mint.Window;
    var output_scroll:mint.Scroll;
    var output_image:mint.Image;


    override function config(config:luxe.AppConfig) {

        return config;

    } //config

    override function ready() {

        tilesets = new Array<TileSet>();

        Luxe.renderer.clear_color.rgb(0x121219);

        
        generator = new Generator();

        init_canvas();
        init_events();
        
#if web
        load_tileset('/input/dirt16.gif');
        load_tileset('/input/template16.gif');
        load_tileset('/input/grass16.gif');
        load_tileset('/input/tiles16.gif');
#elseif desktop
        load_tileset('input/dirt16.gif');
        load_tileset('input/template16.gif');
        load_tileset('input/grass16.gif');
        load_tileset('input/tiles16.gif');
#end

    } //ready


    function init_canvas() {

        rendering = new LuxeMintRender();
        layout = new Margins();

        canvas = new mint.Canvas({
            name:'canvas',
            rendering: rendering,
            options: { color:new Color(1,1,1,0.0) },
            x: 0, y:0, w: Luxe.screen.w, h: Luxe.screen.h
        });

        disp = new Text({
            name:'display.text',
            pos: new Vector(Luxe.screen.w-10, Luxe.screen.h-10),
            align: luxe.TextAlign.right,
            align_vertical: luxe.TextAlign.bottom,
            point_size: 15,
            text: 'usage text goes here'
        });

        create_window_output();
        create_window1();
        create_window_tileset();




        // Export Bitmap button
        var export_bitmap_button = new mint.Button({
            parent: canvas,
            name: 'export_bitmap_button',
            text: 'Export Bitmap',
            align: mint.types.Types.TextAlign.center,
            x: 0, y: Luxe.screen.h-30, w: 100, h: 30,
        });
        layout.margin(export_bitmap_button, bottom, fixed, 0);
        export_bitmap_button.onmouseup.listen(function(e,_){
            export_bitmap();
        });


        // Export TSX button
        var export_tsx_button = new mint.Button({
            parent: canvas,
            name: 'export_tsx_button',
            text: 'Export TSX',
            align: mint.types.Types.TextAlign.center,
            x: 100, y: Luxe.screen.h-30, w: 100, h: 30,
        });
        layout.margin(export_tsx_button, bottom, fixed, 0);
        export_tsx_button.onmouseup.listen(function(e,_){
            export_tsx();
        });
    }

    function add_log(txt:String) {

        disp.text += '\n'+txt;

    }

    function init_events() {

        Luxe.events.listen('config_text.update', function(e:String){
            config_text.text = e;
        });

        Luxe.events.listen('log.add', function(e:String){
            add_log(e);
        });

        

        Luxe.events.listen('generator.done', function(_){

            if(output_image != null) output_image.destroy();

            output_image = new mint.Image({
                parent: output_scroll,
                name: 'image_output',
                x:0, y:0, w:generator.w * 2, h:generator.h * 2,
                path: 'output'
            });
        });

        inline function refresh_tilesets_list(){

            tilesets_list.clear();
            for(ts in tilesets){
                tilesets_list.add_item( create_tileset_li(ts) );
            }

        }

        Luxe.events.listen('tilesets_list.goup', function(o:ControlEvent){

            var idx = tilesets_list.items.indexOf(o.ctrl);
            var nidx = idx-1;

            if(nidx < 0) return;

            var swapper = tilesets[nidx];
            tilesets.splice(nidx, 1);
            tilesets.insert(nidx+1, swapper);
            
            refresh_tilesets_list();

            generator.update_tilesets(tilesets);
        } );

        Luxe.events.listen('tilesets_list.godown', function(o:ControlEvent){

            var idx = tilesets_list.items.indexOf(o.ctrl);
            var nidx = idx+1;

            if(nidx > tilesets.length-1) return;

            var swapper = tilesets[nidx];
            tilesets.splice(nidx, 1);
            tilesets.insert(nidx-1, swapper);
            
            refresh_tilesets_list();

            generator.update_tilesets(tilesets);
        });

        Luxe.events.listen('tilesets_list.remove', function(o:ControlEvent){
            
            var idx = tilesets_list.items.indexOf(o.ctrl);
            var id = tilesets[idx].id;
            var tile_id:Hex = 0;

            tilesets.splice(idx, 1);

            refresh_tilesets_list();

            Luxe.resources.destroy( id, true );

            tile_id = Tile.T1;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T2;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T3;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T1 | Tile.T3;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T2 | Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T1 | Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T2 | Tile.T3;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T1 | Tile.T2;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T3 | Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T2 | Tile.T3 | Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T1 | Tile.T3 | Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T1 | Tile.T2 | Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T1 | Tile.T2 | Tile.T3;
            Luxe.resources.destroy( id+'_'+tile_id, true);
            tile_id = Tile.T1 | Tile.T2 | Tile.T3 | Tile.T4;
            Luxe.resources.destroy( id+'_'+tile_id, true);

            generator.calculate_tiles();

        });
        
            

    }

    function create_window1() {

        window1 = new mint.Window({
            parent: canvas,
            name: 'window1',
            title: 'Configurate',
            options: {
                color:new Color().rgb(0x121212),
                color_titlebar:new Color().rgb(0x191919),
                label: { color:new Color().rgb(0x06b4fb) },
                close_button: { color:new Color().rgb(0x06b4fb) },
            },
            x:10, y:Luxe.screen.h/2-40, w:400, h: 430,
            w_min: 256, h_min:256,
            collapsible:false,
            closable: false,
        });

        path_input = new mint.TextEdit({
            parent: window1,
#if desktop
            text: 'input/template16.gif',
#else
            text: '/input/template16.gif',
#end
            text_size: 12,
            name: 'path',
            options: { view: { color:new Color().rgb(0x19191c) } },
            x: 4, y: 35, w: 340, h: 28,
        });
        layout.margin(path_input, right, fixed, 58);



        load_button = new mint.Button({
            parent: window1,
            name: 'load',
            text: 'LOAD',
            options: { view: { color:new Color().rgb(0x008800) } },
            x: 345, y: 35, w: 54, h: 28,
        });
        layout.anchor(load_button, right, right);
        load_button.onmouseup.listen(function(e,_){
            load_tileset( path_input.text );
        });



        generate_button = new mint.Button({
            parent: window1,
            name: 'generate',
            text: 'Generate!',
            options: { view: { color:new Color().rgb(0x008800) } },
            x: 4, y: 95, w: 400, h: 28,
        });
        layout.margin(generate_button, right, fixed, 2);
        generate_button.onmouseup.listen(function(e,_){
            generator.update_tilesets(tilesets);
            generator.generate();
        });


        config_text = new mint.Label({
            parent: window1,
            text: 'Load the tileset first.',
            text_size: 14,
            align: left,
            x:4, y:65, w:150, h: 30,
        });
        layout.margin(config_text, right, fixed, 4);
        layout.margin(config_text, left, fixed, 4);



        tilesets_list = new mint.List({
            parent: window1,
            name: 'list',
            options: { view: { color:new Color().rgb(0x19191c) } },
            x: 4, y: 130, w: 248, h: 400-130-4
        });

        layout.margin(tilesets_list, right, fixed, 4);
        layout.margin(tilesets_list, bottom, fixed, 4);

    } //create_window1


    function create_window_tileset() {

        window_tileset = new mint.Window({
            parent: canvas,
            name: 'window_tileset',
            title: 'Tileset Preview',
            options: {
                color:new Color().rgb(0x121212),
                color_titlebar:new Color().rgb(0x191919),
                label: { color:new Color().rgb(0x06b4fb) },
                close_button: { color:new Color().rgb(0x06b4fb) },
            },
            x:450, y:Luxe.screen.h/2-40, w:150, h: 300,
            w_min: 150, h_min:256,
            collapsible:false,
            closable: false,
        });

        tileset_title = new mint.Label({
            parent: window_tileset,
            name: 'tileset_title',
            text: 'Select tileset first',
            text_size: 14,
            align: right,
            x:4, y:30, w:150, h: 30,
        });
        layout.margin(tileset_title, right, fixed, 4);
        layout.margin(tileset_title, left, fixed, 4);


        tiles_list = new mint.List({
            parent: window_tileset,
            name: 'list',
            x: 6, y: 60, w: 150, h: 60-100-4
        });
        layout.margin(tiles_list, right, fixed, 6);
        layout.margin(tiles_list, bottom, fixed, 8);

    } // create_window_tileset

    function create_window_output(){

        // Not actually a window...

        output_scroll = new mint.Scroll({
            parent: canvas,
            name: 'scroll1',
            options: { color_handles:new Color().rgb(0xffffff) },
            x:0, y:0, w: Luxe.screen.w-10, h: Luxe.screen.h/2 - 50,
        });

    } // create_window_output

    function create_tileset_li(tileset:TileSet) {

        var _panel = new mint.Panel({
            parent: tilesets_list,
            name: 'panel_${tileset.id}',
            x:2, y:4, w:236, h:64,
        });

        layout.margin(_panel, right, fixed, 8);

        new mint.Image({
            parent: _panel, name: 'icon_${tileset.id}',
            x:0, y:0, w:64, h:64,
            path: tileset.id
        });

        var _title = new mint.Label({
            parent: _panel, name: 'label_${tileset.id}',
            mouse_input:true, x:80, y:8, w:148, h:18, text_size: 16,
            align: TextAlign.left, align_vertical: TextAlign.top,
            text: tileset.id,
        });
        _title.onmouseup.listen(function(e,ctrl){
            var idx = tilesets_list.items.indexOf(ctrl.parent);
            tileset_preview_show(idx);
        });
        layout.margin(_title, right, fixed, 8);

        var _order_up = new mint.Button({
            parent: _panel, name: 'button_${tileset.id}_orderup',
            text: 'up ^',
            x:80, y:36, w:40, h:20, text_size: 16,
            align: TextAlign.center,
        });
        _order_up.onmouseup.listen(function(e,ctrl){
            Luxe.events.fire('tilesets_list.goup', {event: e, ctrl: ctrl.parent});
        });


        var _order_down = new mint.Button({
            parent: _panel, name: 'button_${tileset.id}_orderdown',
            text: 'down v',
            x:80+40, y:36, w:64, h:20, text_size: 16,
            align: TextAlign.center,
        });
        _order_down.onmouseup.listen(function(e,ctrl){
            Luxe.events.fire('tilesets_list.godown', {event: e, ctrl: ctrl.parent});
        });




        var _remove = new mint.Button({
            parent: _panel, name: 'button_${tileset.id}_orderdown',
            text: 'remove',
            x:236-64, y:36, w:64, h:20, text_size: 16,
            align: TextAlign.center,
        });
        _remove.onmouseup.listen(function(e,ctrl){
            Luxe.events.fire('tilesets_list.remove', {event: e, ctrl: ctrl.parent});
        });
        layout.anchor(_remove, right, right);



        return _panel;

    } //create_tileset_li


    function create_tile_li(tile:Tile) {

        var _panel = new mint.Panel({
            parent: tiles_list,
            name: 'panel_${tile.flag}',
            x:4, y:4, w:150, h:Main.tile_size*2+8,
        });

        layout.margin(_panel, right, fixed, 4);

        new mint.Image({
            parent: _panel, name: 'icon_${tile.flag}',
            x:4, y:4, w:Main.tile_size*2, h:Main.tile_size*2,
            path: tile.id,
        });

        var _title = new mint.Label({
            parent: _panel,
            name: 'label_${tile.id}',
            mouse_input:true, x:Main.tile_size*2+8, y:4, w:148, h:18, text_size: 14,
            align: TextAlign.left, align_vertical: TextAlign.top,
            // text: '0x${StringTools.hex(tile.flag)}',
            text: '${tile.flag}',
        });

        layout.margin(_title, right, fixed, 8);

        return _panel;

    } //create_tile_li


    function tileset_preview_show(idx:Int) {

        tileset_title.text = tilesets[idx].id;

        tiles_list.clear();

        for(t in tilesets[idx].tiles){

            tiles_list.add_item( create_tile_li(t) );

        }

    }


    override function onrender() {

        canvas.render();

    } //onrender

    override function update(dt:Float) {

        canvas.update(dt);

    } //update


    override function onmousemove(e) {

        canvas.mousemove( Convert.mouse_event(e) );

    }

    override function onmousewheel(e) {
        canvas.mousewheel( Convert.mouse_event(e) );
    }

    override function onmouseup(e) {
        canvas.mouseup( Convert.mouse_event(e) );
    }

    override function onmousedown(e) {
        canvas.mousedown( Convert.mouse_event(e) );
    }

    override function onkeydown(e:luxe.Input.KeyEvent) {
        canvas.keydown( Convert.key_event(e) );
    }

    override function ontextinput(e:luxe.Input.TextEvent) {
        canvas.textinput( Convert.text_event(e) );
    }

    override function onkeyup(e:luxe.Input.KeyEvent) {

        canvas.keyup( Convert.key_event(e) );

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    function load_tileset(url:String) {

        if(Luxe.resources.texture(url) != null){
            add_log('Tileset was already loaded! (${url})');
            return;
        }

        var load:snow.api.Promise = Luxe.resources.load_texture(url);

        load.then(function(e:Texture){

            var ts:TileSet = new TileSet(e);
            tilesets_list.add_item( create_tileset_li(ts) );

            tilesets.push(ts);

            generator.update_tilesets(tilesets);

        },
        function(_){
            Luxe.resources.remove( Luxe.resources.texture(url) );
            add_log('FAILED to load ${url}');
        });


    }

    function prepare_export(){

        if(!sys.FileSystem.exists(sys.FileSystem.absolutePath('output/'))){
            sys.FileSystem.createDirectory(sys.FileSystem.absolutePath('output/'));
        }

    }


    function export_bitmap() {

        prepare_export();

        var data = format.png.Tools.build32BGRA( generator.w, generator.h, generator.output_pixels.toBytes() );

#if desktop
        var out = sys.io.File.write( sys.FileSystem.absolutePath('output/output.png'), true);
        new format.png.Writer(out).write(data);
        add_log('File saved in output/output.png');
#end

    }

    function export_tsx() {

        prepare_export();

#if desktop
        var out = sys.io.File.write( sys.FileSystem.absolutePath('output/output.tsx'), false);
        sys.io.File.saveContent("output/output.tsx", generator.tsx.toString());
        add_log('File saved in output/output.tsx');
#end

    }


} //Main


typedef ControlEvent = {
     var event:MouseEvent;
     var ctrl:Control;
}
