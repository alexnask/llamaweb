import Server

server := LlamaServer new()
server get("/", |ctx| "<form method=\"post\" action=\"action\"><input type=\"hidden\" name=\"foo\" value=\"bar\" /><input type=\"text\" name=\"woot\" /><input type=\"submit\" value=\"Go!\" /></form>").
post("/action", |ctx|
    data := ""
    ctx post each(|key,val|
        data += key + " is " + val + "<br/>"
    )
    data
).
launch("127.0.0.1:8080")
