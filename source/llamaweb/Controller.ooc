import Server
import Core

Controller: class {
    // FILL ME! :O
    run: func(ctx: HttpContext)->String { "Controller" }
}

extend LlamaServer {
    // Segfaults because of the context :-/
    get: func~controller(route: String, contr: Controller) {
        get(route, |ctx| contr run(ctx))
    }

    post: func~controller(route: String, contr: Controller) {
        post(route, |ctx| contr run(ctx))
    }
}
