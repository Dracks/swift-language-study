import Fluent
import Vapor

struct ErrorHandlerMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response
	{
		do {
			return try await next.respond(to: request)
		} catch {
			switch error {
			case let abort as AbortError:
				switch abort.status {
				case .notFound:
					return notFoundResponse(req: request)
				default:
					throw error
				}
			default:
				throw error
			}
		}
	}
}

func routes(_ app: Application) throws {

	app.middleware.use(ErrorHandlerMiddleware())
	app.middleware.use(SessionsMiddleware(session: app.sessions.driver))
	app.middleware.use(UserSessionAuthenticator())

	try app.register(collection: ProfileController(app: app))
	try app.register(collection: LanguageController(app: app))
	try app.register(collection: RawImportsController(app: app))
	try app.register(collection: DeclinationTypeController())
	try app.register(collection: WordsManagementController())
}
