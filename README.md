# bonjour-http

This library makes it easy to use Bonjour connections among Apple devices (Mac, iPhone, iPad and Apple TV) and use HTTP as the Application layer protocol.

It also has an http-call wrapper, which allows the client to call a specific function on the server side and receive the result asynchronously.

```
// Client-side
connection.call("greeting", params: ["message": "How are you?"]) { (res, json) in
    if res.isSuccess {
        // process the response
        ...
    }
}
```
```
// Server-side
func service(_ service: BonjourService, onCall: String, params: [String : Any], 
             socket: GCDAsyncSocket, context: String) {
    switch(onCall) {
    case "greeting":
        service.respond(to: socket, context: context, 
                        result: ["message": "I'm fine, thank you."])
    default:
        // handle error
        ...
    }
}
```

## Why HTTP?

Bonjour is a great mechanism to establish connections among devices on a local network, but it does not specify how to send various types of data, such as text, JSON data and images. It makes sense to use HTTP, which is widely used not only between browsers and web-servers, but also applications and web services.  

## Classes for Client

**BonjourBrowser** allows an application to discover Bonjour services (NetService objects) with specific type, and present them to the user to choose from (note: this library has no UI code).

**BonjourConnection** allows an application to establish a connection between a Bonjour service selected by the user. The application calls its *send(req:callback:)* method or *call(req:name:params:callback)* method to send an HTTP request to the connected sever, then will receives the responce asynchronously. 

**BonjourConnectionDelegate** is a protocol an application may implement to receive responces not processed by the *callback* function for *send* and *call* method. 

**BonjourRequest** represents an HTTP request, which an application creates and sends using an established BonjourConnection.

**BonjourResponse** represents an HTTP response returned from the Bonjour server. 

## Classes for Server

**BonjourService** allows an application to publish a specific type of Bonjour service. An application needs to define a class respresenting an HTTP server, which implements **BonjourServiceDelegate** protocol. 

**BonjourRequest** represents an HTTP request sent from the client application. The server receives it via service:onRequest:socket:context method of **BonjourServiceDelegate** protocol.

**BonjourResponse** represents an HTTP response, which the server application creates as the response to an HTTP request from the client application. 

Here is an example, which returns "Hello World!" page at the root ("/").

```
class SampleHTTPServer : NSObject, BonjourServiceDelegate {
    func service(_ service: BonjourService, onRequest req: BonjourRequest, socket: GCDAsyncSocket, context: String) {
        var res = BonjourResponse(context: context)
        switch(req.path) {
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

## CocoaPods

I generates two cocoa pods from this repository. 

- https://cocoapods.org/pods/bonjour-http (client & server)
- https://cocoapods.org/pods/bonjour-http-server (server only)

The server-only version is for MacOS applications targeting 10.14. 
The client-side of code uses *ObservableObject* protocol and *@Published* prefix to support SwiftUI, which is available on MacOS 10.15 and later. 
