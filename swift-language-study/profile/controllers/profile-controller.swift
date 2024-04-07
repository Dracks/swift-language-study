import Fluent
import SwiftHtml
import Vapor

struct ProfileController: RouteCollection {
	struct ProfileSave: Content {
		var name: String
		var email: String
		var password: String
		var password2: String
	}

	var app: Application
	var userService = UserService()

	init(app: Application) {
		self.app = app
	}

	func getUserOrThrow(req: Request) throws -> User {
		guard let user = req.auth.get(User.self) else {
			throw Abort(.internalServerError)
		}
		return user
	}

	func boot(routes: Vapor.RoutesBuilder) throws {
		let profileRoutes = routes.grouped(UserIdentifiedMiddleware()).grouped("profile")
		profileRoutes.get(use: profile)
		profileRoutes.get("edit", use: editProfile)
		profileRoutes.post("edit", use: postEditProfile)
	}

	func profile(req: Request) async throws -> Document {
		let user = try getUserOrThrow(req: req)
		return ProfileTemplates(req: req).profile(
			name: user.name ?? "", email: user.email)
	}

	func editProfile(req: Request) async throws -> Document {
		let user = try getUserOrThrow(req: req)
		return ProfileTemplates(req: req).editProfile(user: user)
	}

	func postEditProfile(req: Request) async throws -> Document {
		let user = try getUserOrThrow(req: req)
		var errors: [String: String] = [:]

		let data = try req.content.decode(ProfileSave.self)

		if !data.password.isEmpty || !data.password2.isEmpty {
			if data.password != data.password2 {
				errors["password2"] = "Password 2 must be equal to Password 1"
			}
			let pwdErrors = userService.checkPassword(data.password)
			if pwdErrors.count > 0 {
				let errorsString: String = pwdErrors.joined(separator: ", ")
				errors["password"] =
					"Password doesn't comply the following errors: \(errorsString)"
			}

		}
		if userService.checkEmail(data.email).count > 0 {
			errors["email"] = "Email is mandatory and must be a valid e-mail"
		}
		if errors.count > 0 {
			return ProfileTemplates(req: req).editProfile(user: user, errors: errors)
		} else {
			if !data.password.isEmpty {
				try user.setPassword(pwd: data.password)
			}
			user.email = data.email
			user.name = data.name
			try? await user.save(on: req.db)
			return ProfileTemplates(req: req).editProfile(user: user)
		}
	}
}
