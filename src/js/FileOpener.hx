package js;

#if web

import phoenix.Texture;

import snow.api.buffers.Uint8Array;
import snow.system.assets.Asset.AssetImage;

import js.html.InputElement;
import js.html.File;
import js.html.FileReader;
import js.html.ProgressEvent;

import haxe.io.Bytes;
import haxe.io.BytesData;

class FileOpener {
	var filePicker:InputElement;
	var fileReader:FileReader;
	var dataCallback:Texture->Void;

	public function new() {
		// find the hidden filePicker input element
		// (it was placed there using the custom_index.html file)
		filePicker = cast js.Browser.document.getElementById("filePicker");

		// add a listener for when a user changes its value
		filePicker.addEventListener('change', handleFileSelect, false);
	}

	public function open(dataCallback:Texture->Void) {
		// simulate the user clicking on the hidden file picker
		this.dataCallback = dataCallback;
		untyped fireEvent(filePicker, "click");
	}

	private function handleFileSelect(evt) {
		// make sure they actually clicked something
		if(filePicker.files.length != 1) {
			return;
		}

		var file:File = filePicker.files.item(0);
		if(Luxe.resources.texture(file.name) != null) {
			dataCallback(Luxe.resources.texture(file.name));
			return;
		}

		// cancel any in-progress reads
		if(fileReader != null) {
			fileReader.abort();
			fileReader = null;
		}

		// create a new file reader
		fileReader = new FileReader();

		// fileReader is async, so define a callback for when it's done
		fileReader.onload = function(progress:ProgressEvent) {
			// get the file data as bytes
			var data:BytesData = cast fileReader.result;
			var bytes:Bytes = Bytes.ofData(data);

			// load the image using snow
			Luxe.core.app.assets.image_from_bytes(file.name, Uint8Array.fromBytes(bytes))
				.then(function(asset:AssetImage) {
					// add the image to luxe's resources
					Luxe.resources.add(new Texture({
						id: file.name,
						system: Luxe.resources,
						width: asset.image.width,
						height: asset.image.height,
						pixels: asset.image.pixels
					}));

					// inform the caller that the image was loaded
					dataCallback(Luxe.resources.texture(file.name));
				});
		}

		// read the file data as an array buffer (which can be translated into bytes)
		fileReader.readAsArrayBuffer(file);
	}
}

#end