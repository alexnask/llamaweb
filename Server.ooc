use pcre
import structs/HashMap
import text/[Regexp,StringTokenizer]
import net/[ServerSocket,TCPSocket]
import threading/Thread

extend TCPSocketReader {
    readAll: func -> String {
        data := ""
        while(!data endsWith?("\r\n\r\n")) {
            data += read()
        }
        data
    }
}

Method: enum {
    GET,
    POST
}

HttpContext: class {
    matches: Match
    path: String
    host: String
    headers := HashMap<String,String> new()
    get := HashMap<String,String> new()
    method: Method
    init: func(data: String) {
        if(data startsWith?("GET")) {
            method = Method GET
        } else if(data startsWith?("POST")) {
            method = Method POST
        }

        path = data split(' ',true) get(1)
        if((pos := path find("?",0)) != -1) {
            querystring := path substring(pos+1)
            path = path substring(0,pos)
            querystring split("&",true) each(|param|
                ndex := param find("=",0)
                get add(param substring(0,ndex), param substring(ndex+1))
            )
        }

        lines := data split("\r\n",true) slice(1,-1)
        lines each(|line|
            if((pos := line find(":",0)) != -1) {
                headers add(line substring(0,pos), line substring(pos+1))
            }
        )
    }
}

LlamaServer: class {
    getM := HashMap<String,Func(HttpContext)->String> new()
    postM := HashMap<String,Func(HttpContext)->String> new()

    init: func
    get: func(route: String, f: Func(HttpContext)->String) {
        getM add(route,f)
    }

    post: func(route: String, f: Func(HttpContext)->String) {
        postM add(route,f)
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
                data := client in readAll()
                ctx := HttpContext new(data)
                html := ""
                matched? := false

                if(ctx method == Method GET) {
                    for(key in getM getKeys()) {
                        reg := Regexp compile(key)
                        if(ctx matches = reg matches(ctx path)) {
                            html = getM[key](ctx)
                            matched? = true
                        }
                    }
                } else if(ctx method == Method POST) {
                    for(key in postM getKeys()) {
                        reg := Regexp compile(key)
                        if(ctx matches = reg matches(ctx path)) {
                            html = postM[key](ctx)
                            matched? = true
                        }
                    }
                }

                head := "HTTP/1.1 " + ((matched?) ? "200 OK" : "404 NOT FOUND") + "\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\n\r\n"
                resp := head + html + "\r\n\r\n"
                client out write(resp _buffer data, resp length())
                client out close()
            )
            thread start()
        }
    }
}
