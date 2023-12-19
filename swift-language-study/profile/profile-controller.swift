import Vapor
import Fluent
import SwiftHtml

struct ProfileController: RouteCollection {
    struct Credentials: Content {
        let username: String
        let password: String
    }
    var app: Application
    init(app: Application) {
        self.app = app
    }

    func boot(routes: Vapor.RoutesBuilder) throws {
        let session = routes.grouped([
            SessionsMiddleware(session: app.sessions.driver),
            UserSessionAuthenticator(),
        ])
        session.get("login", use: login)
        session.post("login", use: validateLogin)
        session.get("profile", use: profile)
        session.get("logout", use:logout)

    }

    func login(req: Request) async throws -> Document {
        return Templates.login(username: "")
    }

    func validateLogin(req: Request) async throws -> Response {
        var credentials : Credentials?
        var errorStr = ""
        do {
            credentials = try req.content.decode(Credentials.self)
            if let cred = credentials {
                let optionalUser = try await User.query(on: req.db)
                    .filter(\.$email == cred.username)
                    .first()
                    
                if let user=optionalUser, user.verifyPassword(pwd: cred.password){
                    req.auth.login(user)
                    return req.redirect(to: "/profile")
                } 
                errorStr = "Invalid credentials"
            }
        } catch {
            self.app.logger.error("Some error happened \(error)")
            errorStr = "\(error)"
        }
        let body = Templates.login(username: credentials?.username ?? "", error: errorStr)
        return try await body.encodeResponse(for: req)

    }


    func profile(req: Request) async throws -> Response {
        guard let user = req.auth.get(User.self) else {
            return req.redirect(to: "/login")
        }
        let htmlBody: Document = Templates.profile(name: user.name ?? "", email: user.email)
        return try await htmlBody.encodeResponse(for: req)
    }

    func logout(req: Request) throws -> Response {
        req.auth.logout(User.self)
        req.session.unauthenticate(User.self)
        return req.redirect(to: "/login")
    }

}
