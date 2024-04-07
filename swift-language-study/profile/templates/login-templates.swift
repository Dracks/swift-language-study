import SwiftHtml

class LoginTemplates: Templates {
	func login(username: String, redirect: String?, error: String? = nil) -> Document {
		return layout(
			title: "Log in",
			content:
				Article {
					H1("Login")
					Form {
						if let error = error {
							Div(error).class("error")
						}
						if let redirect = redirect {
							Input().type(.hidden).name("redirect")
								.value(redirect)
						}
						input(
							type: .text, label: "Username",
							name: "username")
						input(
							type: .password, label: "Password",
							name: "password")
						Button("Login").type(.submit)

					}.method(.post)
				}.class("login", "small-form")
		)
	}
}
