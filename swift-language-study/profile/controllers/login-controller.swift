import Fluent
import SwiftHtml
import Vapor

struct LoginController: RouteCollection {
	struct Credentials: Content {
		let username: String
		let password: String
	}
	var app: Application
	init(app: Application) {
		self.app = app
	}

	func boot(routes: Vapor.RoutesBuilder) throws {
		let session = routes
		session.get("login", use: login)
		session.post("login", use: validateLogin)
		session.get("logout", use: logout)

	}

	func login(req: Request) async throws -> Document {
		let redirect: String? = try req.query.get(at: "redirect")
		return LoginTemplates(req: req).login(username: "", redirect: redirect)
	}

	func validateLogin(req: Request) async throws -> Response {
		var credentials: Credentials?
		let redirect: String? = try req.content.get(at: "redirect")
		var errorStr = ""
		do {
			credentials = try req.content.decode(Credentials.self)
			if let cred = credentials {
				let optionalUser = try await User.query(on: req.db)
					.filter(\.$email == cred.username)
					.first()

				if let user = optionalUser, user.verifyPassword(pwd: cred.password)
				{
					req.auth.login(user)
					return req.redirect(to: redirect ?? "/profile")
				}
				errorStr = "Invalid credentials"
			}
		} catch {
			self.app.logger.error("Some error happened \(error)")
			errorStr = "\(error)"
		}
		let body = LoginTemplates(req: req).login(
			username: credentials?.username ?? "", redirect: redirect, error: errorStr)
		return try await body.encodeResponse(for: req)

	}

	func logout(req: Request) throws -> Response {
		req.auth.logout(User.self)
		req.session.unauthenticate(User.self)
		return req.redirect(to: "/login")
	}

}
