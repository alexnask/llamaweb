use pcre
import structs/HashMap
import text/[Regexp,StringTokenizer]
import net/[ServerSocket,TCPSocket]
import threading/Thread

// TODO: urldecode post data :O

extend TCPSocketReader {
    readUntil: func(s: String) -> String {
        data := ""
        while(!data endsWith?(s) && hasNext?()) {
            data += read()
        }
        data
    }
}

extend String {
    parseQuery: func -> HashMap<String,String> {
        ret := HashMap<String,String> new()
        split("&",true) each(|param|
            pos := param find("=",0)
            ret add(param substring(0,pos),param substring(pos+1))
        )
        ret
    }
}

Method: enum {
    GET,
    POST
}

HttpContext: class {
    server: LlamaServer
    matches: Match
    path: String
    host: String
    headers := HashMap<String,String> new()
    get := HashMap<String,String> new()
    post := HashMap<String,String> new()
    method: Method
    init: func(data: String) {
        if(data startsWith?("GET")) {
            method = Method GET
        } else if(data startsWith?("POST")) {
            method = Method POST
        }

        path = data split(' ',true) get(1)
        if((pos := path find("?",0)) != -1) {
            get = path substring(pos+1) parseQuery()
            path = path substring(0,pos)
        }

        lines := data split("\r\n",true) slice(1,-1)
        lines each(|line|
            if((pos := line find(":",0)) != -1) {
                headers add(line substring(0,pos), line substring(pos+1) trimLeft())
            }
        )
    }
}

LlamaServer: class {
    contentType := "text/html; charset=utf-8"
    getM := HashMap<String,Func(HttpContext)->String> new()
    postM := HashMap<String,Func(HttpContext)->String> new()

    init: func
    get: func(route: String, f: Func(HttpContext)->String) {
        getM add("^" + route + "$",f)
    }

    post: func(route: String, f: Func(HttpContext)->String) {
        postM add("^" + route + "$",f)
    }

    launch: func(s: String) {
        port := 80
        ip := s
        if((pos := s find(":",0)) != -1) {
            ip = s substring(0,pos)
            port = s substring(pos+1) toInt()
        }
        sock := ServerSocket new(ip,port)
        sock listen()

        while(true) {
            client := sock accept()
            thread := Thread new(||
                data := client in readUntil("\r\n\r\n")
                ctx := HttpContext new(data)
                ctx server = this
                if(ctx method == Method POST && ctx headers["Content-Length"]) {
                    size := ctx headers["Content-Length"] toInt()
                    cdata := CString new(size)
                    client in read(cdata,0,size)
                    if(cdata) ctx post = cdata toString() parseQuery()
                }
                html := ""
                matched? := false

                if(ctx method == Method GET) {
                    for(key in getM getKeys()) {
                        reg := Regexp compile(key,RegexpOption ANCHORED)
                        if(ctx matches = reg matches(ctx path)) {
                            html = getM[key](ctx)
                            matched? = true
                        }
                    }
                } else if(ctx method == Method POST) {
                    for(key in postM getKeys()) {
                        reg := Regexp compile(key,RegexpOption ANCHORED)
                        if(ctx matches = reg matches(ctx path)) {
                            html = postM[key](ctx)
                            matched? = true
                        }
                    }
                }

                head := "HTTP/1.1 " + ((matched?) ? "200 OK" : "404 NOT FOUND") + "\r\nContent-Type: " + contentType + "\r\nConnection: close\r\n\r\n"
                resp := head + html + "\r\n\r\n"
                client out write(resp _buffer data, resp length())
                client out close()
            )
            thread start()
        }
    }
}
