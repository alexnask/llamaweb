import Server,Controller

FileController: class extends Controller {
    base := ""

    run: func(ctx: HttpContext)->String {
        path := base + ctx path trimLeft('/')
        if(file := FStream open(path,"rb")) {
            size := file getSize()
            cdata := CString new(size)
            file read(cdata,size)
            return cdata toString()
        }
        "FileController could not find specified file."
    }
}

Llama: class {
    fileController := static FileController new()
}

