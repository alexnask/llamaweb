import llamaweb/[Router, Server]

// TODO: Implement FastCGI or SCGI or something like that :P
llama := Server new(9999)

// Get a router to all hosts
r := llama router("*.example.com")

blog := r sub("blog.example.com")

// If the queried document is for example /css/style.css, we look in /public/css for it
r static("/css", "/public/css") . static("/images", "/public/images") . get("/", |resp|
    resp ok("Hello World!")
) . get("/blog/*", |resp, matches|

	// Matches is a HashBag
    resp redirect("blog.example.com/#{matches get("1", String)}")
) . rest(|resp|
    // This matches when all other rules don't
    resp notFound("The document you are looking for doesn't exist")
)

blog get("/posts", |resp|
    // List some posts!
    resp ok("No posts here!")
) . get("/posts/id(%d)", |resp, matches|
    // Find a post
    // Here, to get the id we would do matches get("id", Int)
    resp notFound("The document you are looking for doesn't exist")
)

llama run()
