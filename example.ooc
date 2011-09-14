import llamaweb/Server

server := LlamaServer new()
server get("/(.*)", |ctx| ctx path). launch("127.0.0.1:8080")
