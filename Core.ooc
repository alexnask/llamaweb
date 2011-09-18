import Server,Controller
import structs/HashMap
import text/StringTokenizer
import io/File

FileController: class extends Controller {
    mimetypes: static HashMap<String,String>
    loadMimeTypes: static func {
        This mimetypes = HashMap<String,String> new()
        mimeFile := File new("mimetypes.cfg")
        if(mimeFile file?()) {
            mimeFile read() split('\n',false) each(|line|
                if(!line empty?()) {
                    parts := line split(':',false)
                    This mimetypes[parts first()] = parts last()
                }
            )
        }
    }

        base := ""

    run: func(ctx: HttpContext)->String {
        path := base + ctx path trimLeft('/')
        if((file := File new(path)) file?()) {
            ctx server contentType = This mimetypes get(path split('.') last())
            return file read()
        }
        "FileController could not find specified file."
    }
}

Llama: class {
    fileController := static FileController new()
}

FileController loadMimeTypes()
