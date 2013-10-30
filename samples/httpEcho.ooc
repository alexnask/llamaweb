import llamaweb/[Router, Server]

// TODO: Implement FastCGI or SCGI or something like that :P
llama := Server new(9999)

// Get a router to all hosts
r := llama router("*")
// Match to anything! o/
r any("*", |resp|
    resp ok(resp request body)
)

llama run()
