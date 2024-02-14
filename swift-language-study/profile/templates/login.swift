import SwiftHtml

extension Templates {
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

	func profile(name: String, email: String) -> Document {
		return layout(
			title: "My profile",
			content: Main {
				Article {
					H1("My Profile")
					Fieldset {
						Label("Name: ")
						Span(name)
					}
					Fieldset {
						Label("Email: ")
						Span(email)
					}
				}
			}.class("container"))
	}
}
