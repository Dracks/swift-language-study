import Vapor 

func notFoundResponse(req: Request) -> Response {
    return .init(status: .notFound, body: .init(string: Templates.notFound().render()))
}