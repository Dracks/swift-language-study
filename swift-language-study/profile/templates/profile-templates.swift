import FluentKit
import SwiftHtml
import Vapor

class UserView {
	var id: UUID?
	var name: String
	var email: String
	var password: String = ""
	var isAdmin: Bool

	init(id: UUID? = nil, email: String, password: String, name: String, isAdmin: Bool = false)
	{
		self.id = id
		self.email = email
		self.name = name
		self.password = password
		self.isAdmin = isAdmin
	}

	init(fromUser user: User) {
		id = user.id
		name = user.name ?? ""
		email = user.email
		isAdmin = user.isAdmin
	}
}

class ProfileTemplates: Templates {
	func profile(name: String, email: String) -> Document {
		return layout(
			title: "My profile",
			content:
				Article {
					Nav {
						H1("My Profile")
						Ul {
							A("Edit").href("/profile/edit").class(
								"button")
						}
					}
					Fieldset {
						Label("Name: ")
						Span(name)
					}
					Fieldset {
						Label("Email: ")
						Span(email)
					}
				})
	}

	func listProfiles(_ usersPage: Page<User>) -> Document {
		return layout(
			title: "Admin Users list",
			content: Article {
				Nav {
					Ul {
						A("New user").href("new").role("button")
					}
				}
				Table {
					Tr {
						Th("Name")
						Th("Email")
						Th("Type")
						Th()
					}
					for user in usersPage.items {
						Tr {
							Td(user.name)
							Td(user.email)
							Td(user.isAdmin ? "admin" : "user")
							Td {
								A("edit").href(
									"/users/edit/\(user.id?.uuidString ?? "")"
								)
							}
						}
					}
				}
				paginate(metadata: usersPage.metadata)
			}
		)
	}

	func editProfile(user: User, errors: [String: String] = [:]) -> Document {
		return layout(
			title: "Edit my profile",
			content: Article {
				H1("Edit your profile")
				Form {
					input(
						type: .text, label: "Name:", name: "name",
						value: user.name ?? "", error: errors["name"])
					input(
						type: .email, label: "Email:", name: "email",
						value: user.email, required: true,
						error: errors["email"])
					input(
						type: .password, label: "Password: ",
						name: "password", error: errors["password"])
					input(
						type: .password, label: "Repeat the password:",
						name: "password2", error: errors["password2"])
					Button("Save").type(.submit)
				}.method(.post)

			})
	}

	func editAdminProfile(user: UserView?, errors: [String: String] = [:]) -> Document {
		var title = "New User"
		var save = "Create"
		var requirePasswd = true
		if let user = user {
			title = "Edit \(user.email)"
			save = "Save"
			requirePasswd = user.id == nil
		}
		let isAdmin = user?.isAdmin ?? false
		return layout(
			title: title,
			content: Article {
				H1(title)
				Form {
					input(
						type: .text, label: "Name:", name: "name",
						value: user?.name ?? "", error: errors["name"])
					input(
						type: .email, label: "Email:", name: "email",
						value: user?.email ?? "", required: true,
						error: errors["email"])
					input(
						type: .password, label: "Password: ",
						name: "password", value: user?.password ?? "",
						required: requirePasswd,
						error: errors["password"])
					Label("User type").for("userType")
					Select {
						Option("User").value("user").selected(
							isAdmin == false)
						Option("Admin").value("admin").selected(
							isAdmin == true)
					}.name("userType")

					Button(save).type(.submit)
				}.method(.post)
			})
	}
}
