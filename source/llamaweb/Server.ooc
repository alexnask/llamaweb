use pcre
import structs/HashMap
import text/[Regexp,StringTokenizer]
import net/[ServerSocket,TCPSocket]
import threading/Thread


use web
use fastcgi

import Router
import fastcgi/fastcgi


_LlamaApplication: class extends Application {
    _router: Router
    init: func(=_router)

    processRequest: func {
        ctx := Context new(request, response)
        if(!_router handle(ctx)) {
            ctx notFound("You confused the llama.")
        }
    }

    spawn: func -> This { this }
}

Server: class {
    _fcgi: FCGIServer

    _router := Router new("*")

    init: func(socketPath: String) {
        _fcgi = FCGIServer new(socketPath)

        _fcgi setApplication(_LlamaApplication new(_router))
    }

    init: func(port: Int) {
        init(":#{port}")
    }

    router: func(hostPath: String) -> Router {
        _router sub(hostPath)
    }

    router: func~empty -> Router { _router }

    run: func -> Bool {
        _fcgi run()
    }
}
