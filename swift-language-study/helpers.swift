import Vapor

func notFoundResponse(req: Request) -> Response {
	return .init(
		status: .notFound, body: .init(string: Templates(req: req).notFound().render()))
}

class GenericError: Error {
	let message: String

	init(msg: String) {
		message = msg
	}
}
