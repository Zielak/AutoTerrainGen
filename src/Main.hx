
import luxe.Input;

import luxe.Color;
import luxe.Component;
import luxe.options.SpriteOptions;
import luxe.Rectangle;
import luxe.Sprite;
import luxe.Vector;
import luxe.Text;
import luxe.Screen;
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
    var grid_bg:Sprite;

    var export_bitmap_button:mint.Button;
    var export_tsx_button:mint.Button;

#if web
    var fileOpener:js.FileOpener;
#end


    override public function config(config:luxe.AppConfig) {

        config.preload.textures.push({ id:'input/grid.gif' });

        return config;

    } //config

    override function ready() {

        tilesets = new Array<TileSet>();

        Luxe.renderer.clear_color.rgb(0x121219);

        
        generator = new Generator();

        init_canvas();
        init_events();
        
#if web
        fileOpener = new js.FileOpener();
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

    override function onwindowresized(event:WindowEvent) {

        return;

        // FAIL

        canvas.w = event.event.x;
        canvas.h = event.event.y;



        disp.pos.x = Luxe.screen.w-10;
        disp.pos.y = Luxe.screen.h-10;

        export_bitmap_button.y = Luxe.screen.h-50;
        export_tsx_button.y = Luxe.screen.h-50;

        refresh_output();
        refresh_window1();

        // Luxe.camera.size_mode = luxe.Camera.SizeMode.cover;

        // Luxe.camera.viewport.x = -event.event.x + Luxe.camera.viewport.w;
        // Luxe.camera.viewport.y = -event.event.y + Luxe.camera.viewport.h;

        trace('Viewport: ${Luxe.camera.viewport.x}, ${Luxe.camera.viewport.y}');
        trace('Vie_size: ${Luxe.camera.viewport.w}, ${Luxe.camera.viewport.h}');

    }

    function refresh_output() {

        output_scroll.x = Math.floor( Luxe.screen.width/2 );
        output_scroll.y = 0;
        output_scroll.w = Math.floor( Luxe.screen.width/2 );
        output_scroll.h = Math.floor( Luxe.screen.height - 50 - 2 );

        grid_bg.pos.x = Math.floor( Luxe.screen.width/2 );
        grid_bg.pos.y = 0;
        grid_bg.size.x = Math.floor( Luxe.screen.width/2 );
        grid_bg.size.y = Math.floor( Luxe.screen.height - 50 - 2 );

    }

    function refresh_window1() {

        // output_scroll.h = Math.floor( Luxe.screen.height/2 );
        // output_scroll.y = Math.floor( Luxe.screen.height/2 );
        
    }




    function init_canvas() {

        rendering = new LuxeMintRender();
        layout = new Margins();

        canvas = new mint.Canvas({
            name:'canvas',
            rendering: rendering,
            options: { color:new Color(1,1,1,0.0) },
            x: 0, y:0, w: Luxe.screen.w, h: Luxe.screen.h
        });

        create_output_window();

        disp = new Text({
            name:'display.text',
            bounds: new luxe.Rectangle(10, Luxe.screen.h/2, Luxe.screen.w/2-20, Luxe.screen.h/2 -10),
            bounds_wrap: true,
            align: luxe.TextAlign.right,
            align_vertical: luxe.TextAlign.bottom,
            point_size: 15,
            text: 'usage text goes here'
        });

        create_configuration_window();
        create_tileset_window();




        // Export Bitmap button
        export_bitmap_button = new mint.Button({
            parent: canvas,
            name: 'export_bitmap_button',
            text: 'Export Bitmap',
            align: mint.types.Types.TextAlign.center,
            x: Luxe.screen.w/2, y: Luxe.screen.h-50, w: 100, h: 50,
        });
        layout.margin(export_bitmap_button, bottom, fixed, 0);
        export_bitmap_button.onmouseup.listen(function(e,_){
            export_bitmap();
        });


        // Export TSX button
        export_tsx_button = new mint.Button({
            parent: canvas,
            name: 'export_tsx_button',
            text: 'Export TSX',
            align: mint.types.Types.TextAlign.center,
            x: Luxe.screen.w/2+102, y: Luxe.screen.h-50, w: 100, h: 50,
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

        Luxe.events.listen('tilesets_list.rename', function(o:TextEditEvent){

            tilesets[tilesets_list.items.indexOf(o.ctrl)].name = o.text;

        } );

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

    function create_configuration_window() {

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
            x:10, y:10, w:400, h: 430,
            w_min: 256, h_min:256,
            collapsible:false,
            closable: false,
        });

#if desktop
        path_input = new mint.TextEdit({
            parent: window1,
            text: 'input/',
            text_size: 12,
            name: 'path',
            options: { view: { color:new Color().rgb(0x19191c) } },
            x: 4, y: 35, w: 340, h: 28,
        });
        layout.margin(path_input, right, fixed, 58);
#end



        load_button = new mint.Button({
            parent: window1,
            name: 'load',
            text: 'LOAD',
            options: { view: { color:new Color().rgb(0x008800) } },
#if desktop
            x: 345, y: 35, w: 54, h: 28,
#elseif web
            x: 4, y: 35, w: 340, h: 28,
#end
        });
        layout.anchor(load_button, right, right);
        load_button.onmouseup.listen(function(e,_){
#if desktop
            load_tileset( path_input.text );
#elseif web
            fileOpener.open(function(e:Texture) {
                // code taken from load_tileset
                // TODO: abstract it out to keep things DRY
                var ts:TileSet = new TileSet(e);
                tilesets_list.add_item( create_tileset_li(ts) );

                tilesets.push(ts);

                generator.update_tilesets(tilesets);
            });
#end
        });


        var tilesize_txt = new mint.TextEdit({
            parent: window1,
            text: '16',
            text_size: 16,
            name: 'tile_size_txt',
            options: { view: { color:new Color().rgb(0x19191c) } },
            x: 350, y: 65, w: 50, h: 28,
        });
        layout.anchor(tilesize_txt, right, right);
        tilesize_txt.onchange.listen(function(s:String){

            var i:Int = Math.floor( Std.parseFloat(s) );
            if(i < 1){
                add_log('Invalid tile size: ${s} -> ${i}');
            }
            if(i > 0){
                Main.tile_size = i;
                add_log('Tile size changed to ${Main.tile_size}');
                if( tilesets.length > 0 ){
                    add_log('WARNING: tilesets that don\'t match this size can cause problems.');
                }
            }
        });
        var tilesize_label = new mint.Label({
            parent: window1,
            text: 'tile size:',
            text_size: 14,
            align: right,
            x:300, y:65, w:50, h: 28,
        });
        layout.anchor(tilesize_label, tilesize_txt, right, left);




        generate_button = new mint.Button({
            parent: window1,
            name: 'generate',
            text: 'GENERATE!',
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

    } //create_configuration_window


    function create_tileset_window() {

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
            x:430, y:10, w:150, h: 430,
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
            name: 'tiles_list',
            x: 6, y: 60, w: 150, h: 60-100-4
        });
        layout.margin(tiles_list, right, fixed, 6);
        layout.margin(tiles_list, bottom, fixed, 8);

    } // create_tileset_window

    function create_output_window(){

        // Not actually a window...

        output_scroll = new mint.Scroll({
            parent: canvas,
            name: 'output_scroll',
            options: {
                color_handles:new Color().rgb(0xffffff),
                color:new Color(0.13, 0.17, 0.2, 0.5),
            },
            x:Luxe.screen.w/2, y:0, w: Luxe.screen.w/2, h: Luxe.screen.h/2 - 50 - 2,
        });

        // Chess background
        grid_bg = new Sprite({
            name:'grid_bg',
            texture: Luxe.resources.texture('input/grid.gif'),
            uv: new Rectangle(0, 0, Luxe.screen.w/2, Luxe.screen.h - 52),
            centered: false,
            size: new Vector(Luxe.screen.w/2, Luxe.screen.h - 52),
            pos: new Vector(Luxe.screen.w/2, 0),
            depth: -1,
        });
        grid_bg.texture.filter_mag = grid_bg.texture.filter_min = nearest;
        grid_bg.texture.clamp_s = grid_bg.texture.clamp_t = repeat;

        refresh_output();

    } // create_output_window

    function create_tileset_li(tileset:TileSet) {

        var _panel = new mint.Panel({
            parent: tilesets_list,
            name: 'panel_${tileset.id}',
            x:2, y:4, w:236, h:64,
        });

        layout.margin(_panel, right, fixed, 8);

        var _img = new mint.Image({
            parent: _panel, name: 'icon_${tileset.id}',
            x:0, y:0, w:64, h:64,
            mouse_input:true,
            path: tileset.id
        });
        _img.onmouseup.listen(function(e,ctrl){
            var idx = tilesets_list.items.indexOf(ctrl.parent);
            tileset_preview_show(idx);
        });

        var _title = new mint.TextEdit({
            parent: _panel,
            text: tileset.name,
            text_size: 16,
            name: 'tileset_name_${tileset.id}',
            options: { view: { color:new Color().rgb(0x19191c) } },
            x:80, y:8, w:148, h:18
        });
        layout.margin(_title, right, fixed, 0);
        _title.onchange.listen( function(s){
            Luxe.events.fire('tilesets_list.rename', {text: s, ctrl: _title.parent});
        } );

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

#if !web
        if(!sys.FileSystem.exists(sys.FileSystem.absolutePath('output/'))){
            sys.FileSystem.createDirectory(sys.FileSystem.absolutePath('output/'));
        }
#end

    }


    function export_bitmap() {

        prepare_export();

#if desktop
        var data = format.png.Tools.build32BGRA( generator.w, generator.h, generator.output_pixels.toBytes() );
        var out = sys.io.File.write( sys.FileSystem.absolutePath('output/output.png'), true);
        new format.png.Writer(out).write(data);
        add_log('File saved in output/output.png');
#elseif web
        var data:js.html.Uint8Array = js.BuildPNG.build(generator.w, generator.h, generator.output_pixels.toBytes());
        var blob:js.html.Blob = new js.html.Blob([data], {type: 'image/png'});
        js.html.FileSaver.saveAs(blob, "output.png");
        add_log("File saved as output.png");
#end

    }

    function export_tsx() {

        prepare_export();

#if desktop
        var out = sys.io.File.write( sys.FileSystem.absolutePath('output/output.tsx'), false);
        sys.io.File.saveContent("output/output.tsx", generator.tsx.toString());
        add_log('File saved in output/output.tsx');
#elseif web
        var blob:js.html.Blob = new js.html.Blob([generator.tsx.toString()], {type: 'text/xml;charset=utf8'});
        js.html.FileSaver.saveAs(blob, "output.tsx");
        add_log('File saved as output.tsx');
#end

    }


} //Main


typedef ControlEvent = {
     var event:MouseEvent;
     var ctrl:Control;
}
typedef TextEditEvent = {
     var text:String;
     var ctrl:Control;
}
