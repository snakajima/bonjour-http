# bonjour-http

This library makes it easy to use Bonjour connections among Apple devices (Mac, iPhone, iPad and Apple TV) and use HTTP as the Application layer protocol.

It also has an http-call wrapper, which allows the client to call a specific function on the server side and receive the result asynchronously.

```
// Client-side
let json = [
    "message": "Hello World"
]
connection.call("greeting", params: json) { (res, json) in
    if let res.isSuccess {
        print("Response from server", json)
    }
}
```
```
// Server-side
class SampleHTTPServer : NSObject, BonjourServiceDelegate {
    func service(_ service: BonjourService, onCall function: String, params: [String : Any], socket: GCDAsyncSocket, context: String) {
        switch(function) {
        case "greeting":
            let json = [
                "result": "How are you?"
            ]
            service.respond(to: socket, context: context, result: json)
        default:
            // handle error
            ...
        }
    }
    ...
}
```

## Why HTTP?

Bonjour is a great mechanism to establish connections among devices on a local network, but it does not specify how to send various types of data, such as text, JSON data and images. It makes sense to use HTTP, which is widely used not only between browsers and web-servers, but also applications and web services.  

## Classes for Client

**BonjourBrowser** allows an application to discover Bonjour services (NetService objects) with specific type, and present them to the user to choose from (note: this library has no UI code).

**BonjourConnection** allows an application to establish a connection between a Bonjour service selected by the user. The application calls its send(req:) method to send an HTTP request to the connected sever. In order to receive responces from the server, the application needs to create an object, which implements **BonjourConnectionDelegate** protocol. 

**BonjourRequest** represents an HTTP request, which an application creates and send using an established BonjourConnection.

**BonjourResponce** represents an HTTP responce from the Bonjour server. 

## Classes for Server

**BonjourService** allows an application to publish a specific type of Bonjour service. An application needs to define a class respresenting HTTP server, which implements **BonjourServiceDelegate** protocol. 

Here is an example, which always returns "Hello World!" page regardless of the path.

```
class SampleHTTPServer : NSObject, BonjourServiceDelegate {
    func on(reqeust: BonjourRequest, service: BonjourService, socket: GCDAsyncSocket) {
        var res = BonjourResponce()
        switch(reqeust.path) {
        case "/":
            res.setBody(string: "<html><body>Hello World!</body></html>")
        default:
            res.setBody(string: "<html><body>Page Not Found</body></html>")
            res.statusText = "404 Not Found"
        }
        service.send(responce: res, to: socket)
    }
}
```
