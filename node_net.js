import net from "node:net";

let health_response = JSON.stringify({"message" : "sucessful"});
const put_response = JSON.stringify({"message" : "successful put request executed"});
const response_404 = JSON.stringify({"message" : "404 path not found , please check your method and response"});


const server = net
  .createServer((socket) => {
    socket.on("data", (data) => {
      console.log(data.toString());
      const request = data.toString().split("\r\n");
      
      const req_meta = request[0].split(" ");
      const method = req_meta[0];
      const path = req_meta[1];
      
      console.log(method);
      
      if (method == "GET") {
        if (path == "/health") {
          socket.write(
            "HTTP/1.1 200 OK\r\n" +
              "Content-Type: application/json\r\n" +
              `Content-Length: ${Buffer.byteLength(health_response)}\r\n` +
              "\r\n" +
              `${health_response}`
          );
        }else{
            socket.write(
                "HTTP/1.1 200 OK\r\n" +
                  "Content-Type: application/json\r\n" +
                  `Content-Length: ${Buffer.byteLength(response_404)}\r\n` +
                  "\r\n" +
                  `${response_404}`
              );    
        }
      }


    if(method == "PUT"){

        const content_type = data.toString().match(/Content-Type:\s*([^\r\n;]*)/im)[1];
        
        console.log(content_type);;
        const put_method_body = JSON.parse((data.toString().split('\r\n\r\n')[1]).split('\r\n')[0])
    
        if(path == "/changeHealth" && content_type == "application/json"){
            
            health_response = JSON.stringify({health : put_method_body.health})

            socket.write(
                "HTTP/1.1 200 OK\r\n" +
                  "Content-Type: application/json\r\n" +
                  `Content-Length: ${Buffer.byteLength(put_response)}\r\n` +
                  "\r\n" +
                  `${put_response}`
              );

        }else{
            socket.write(
                "HTTP/1.1 200 OK\r\n" +
                  "Content-Type: application/json\r\n" +
                  `Content-Length: ${Buffer.byteLength(response_404)}\r\n` +
                  "\r\n" +
                  `${response_404}`
              );
        }

    }
     
    
    socket.end();
    
    
    });



  })
  .on("error", (err) => {
    // Handle errors here.
    throw err;
  });

server.listen(
  {
    host: "localhost",
    port: 8080,
    exclusive: true,
  },
  () => {
    console.log("opened server on", server.address());
  }
);
