import SwiftHtml
import Vapor

class Templates {
    static func input(type: Input.`Type`, label: String, name: String, value: String="", error: String?=nil) -> Tag {
        return Div{
            Label(label).attribute("for", name)
            Input().type(type).name(name).value(value)
        }
    }

    static func notFound() -> Document {
        return layout(title: "Not found", content: Main{
            Article{
                H1("Not found")
                Div("Page not found")
            }
        })
    }
    
    static func layout(title: String, content: Tag) -> Document {
        return Document(.html){
            Html{
                Head{
                    Title(title)
                    Link(rel: .stylesheet).href("/assets/pico.classless.css")
                    Link(rel: .stylesheet).href("/assets/custom.css")
                }
                Body {
                    [content]
                }
            }
        }
    }
}

let renderer = DocumentRenderer(minify: false, indent: 2)

extension Document : ResponseEncodable, AsyncResponseEncodable {

    public func render() -> String {
        return renderer.render(self)
    }
    
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
      var headers = HTTPHeaders()
      headers.add(name: .contentType, value: "text/html")
      return request.eventLoop.makeSucceededFuture(.init(
        status: .ok, headers: headers, body: .init(string: self.render())
      ))
    }
    

    public func encodeResponse(for request: Request) async throws -> Response {
      var headers = HTTPHeaders()
      headers.add(name: .contentType, value: "text/html")
        return .init(status: .ok, headers: headers, body: .init(string: self.render()))
    }
}


