import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

class Macros {
	public static macro function getColorData(filename:String):ExprOf<{
		connected:String,
		disconnected:String
	}> {
		var posInfos = Context.getPosInfos(Context.currentPos());
		var directory = Path.directory(posInfos.file);

		var filePath:String = Path.join([directory, filename]);

		if (FileSystem.exists(filePath)) {
			var content = File.getContent(filePath);
			return macro $v{haxe.Json.parse(content)};
		} else {
			return macro null;
		}
	}
}
