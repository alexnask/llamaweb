use pcre, web
import text/Regexp
import structs/[ArrayList, HashBag, HashMap]
import io/Writer

import web/Application

Context: class {
    request: Request
    response: Response

    init: func(=request, =response)


    ok: func(s: String) {
        response setStatus(200, "OK")
        response body() write(s)
    }

    notFound: func(s: String) {
        response setStatus(404, "NOT FOUND")
        response body() write(s)
    }
}

Route: cover {
    // If method is null, this can be matched against any http method
    method: String
    pattern: Regexp

    action: Func(Context, HashBag)
}

Router: class {

    children := ArrayList<This> new(3)
    _hostPattern: Regexp
    routes := ArrayList<Route> new(15)

    init: func(str: String) {
        _hostPattern = Regexp compile("^${str}$", RegexOption ANCHORED)
    }

    sub: func(str: String) -> Router {
        r := Router new(str)
        children add(r)
        r
    }

    addRoute: func(route: Route) {
        routes add(route)
    }

    method: func(m: String, str: String, action: Func(Context, HashBag)) {
        // We need to copy the closure's context if we call it later, before it goes out of scope! :D
        closure: Closure* = gc_malloc(Closure size)
        memcpy(closure, action&, Closure size)

        pattern := Regexp compile("^#{str}$", RegexOption ANCHORED)

        addRoute((m, pattern, closure@ as Func(Context, HashBag)) as Route)
    }

    get: func(str: String, action: Func(Context, HashBag)) {
        method("get", str, action)
    }

    post: func(str: String, action: Func(Context, HashBag)) {
        method("post", str, action)
    }

    put: func(str: String, action: Func(Context, HashBag)) {
        method("put", str, action)
    }

    delete: func(str: String, action: Func(Context, HashBag)) {
        method("delete", str, action)
    }

    any: func(str: String, action: Func(Context, HashBag)) {
        method(null, str, action)
    }

    handle: func(ctx: Context) -> Bool {
        if(!_hostPattern matches(ctx request remoteHost)) return false

        for(child in children) {
            if(child handle(ctx)) return true
        }

        for(route in routes) {
            matches := route pattern matches(ctx request path)
            if(matches) {
                hashBag := HashBag new()
                // Fill the hashBag from the matches
                route action(ctx, hashBag)
                return true
            }
        }

        false
    }
}
