import net from "node:net";

const server = net
  .createServer((socket) => {

    socket.on('data', (data) => {

        console.log(data.toString())
        const request = (data.toString()).split('\r\n');
        const req_meta = request[0].split(" ")
        const method = req_meta[0]
        const path = req_meta[1]

        console.log(method);
        const response = "heyyyyyyy check this "

        if(method == "GET"){

            if(path == "/health"){

                socket.write("HTTP/1.1 200 OK\r\n" +
                    "Content-Type: text/plain\r\n" +
                    `Content-Length: ${response.length}\r\n` + 
                    "\r\n" + 
                    `${response}`)
            }
            
        }

        
        // console.log(data.toString())
        // socket.write("HTTP/1.1 200 OK\r\n" +
        // "Content-Type: text/plain\r\n" +
        // "Content-Length: 13\r\n" + 
        // "\r\n" + 
        // "Hello, Client"

        // )
        socket.end();
    })

    })
  .on("error", (err) => {
    // Handle errors here.
    throw err;
  });

server.listen({

    host: 'localhost',
    port: 8080,
    exclusive: true,


},() => {
  console.log("opened server on", server.address());
});
