import FluentKit
import SwiftHtml
import Vapor

class Templates {
	let user: User?

	init(req: Request) {
		self.user = req.auth.get(User.self)
	}
	func input(
		type: Input.`Type`,
		label: String,
		name: String,
		value: String = "",
		required: Bool = false,
		error: String? = nil,
		tabIndex: Int? = nil
	) -> Tag {
		var input = Input().type(type).name(name).value(value).required(required)
		if let tabIndex = tabIndex {
			input = input.tabindex(tabIndex)
		}
		return Div {
			Label(label).attribute("for", name)
			input
			if let error = error {
				Div(error).class("error")
			}
		}
	}

	func notFound() -> Document {
		return layout(
			title: "Not found",
			content: Main {
				Article {
					H1("Not found")
					Div("Page not found")
				}
			})
	}

	func layout(title: String, content: Tag) -> Document {
		return Document(.html) {
			Html {
				Head {
					Title(title)
					Link(rel: .stylesheet).href("/assets/pico2.min.css")
					Link(rel: .stylesheet).href("/assets/pico2.colors.min.css")
					Link(rel: .stylesheet).href("/assets/custom.css")
					Link(rel: .stylesheet).href(
						"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"
					)
					Script().src("/assets/htmx.min.js")
					Meta().charset("UTF-8")
				}
				Body {
					Header {
						Nav {
							Ul {
								Li {
									A("Home").href("/")
										.role(
											"button"
										)
								}
								if user?.isAdmin ?? false {
									Li {
										Details {
											Summary(
												"Admin"
											)
											.role(
												"button"
											)
											Ul {
												Li {
													A(
														"Words"
													)
													.href(
														"/words-management/list"
													)
												}
												Li {
													A(
														"Languages"
													)
													.href(
														"/languages/"
													)
												}
												Li {
													A(
														"Imported words"
													)
													.href(
														"/raw-imports/"
													)
												}
												Li {
													A(
														"Variations"
													)
													.href(
														"/declinations-form/edit"
													)
												}
												Li {
													A(
														"Users"
													)
													.href(
														"/users/"
													)
												}
											}
										}.class("dropdown")
									}
								}
							}

							Ul {
								if user == nil {
									Li {
										A("Login")
											.href(
												"/login"
											)
											.role(
												"button"
											)
									}
								} else {
									Li {
										A("Profile")
											.href(
												"/profile"
											)
											.role(
												"button"
											)
									}
									Li {
										A("Logout")
											.href(
												"/logout"
											)
											.role(
												"button"
											)
											.class(
												"danger"
											)
									}
								}
							}
						}
					}.class("container")
					Main {
						content
					}.class("container")
					Footer {
						Div {
							A("Swift language study").href(
								"https://gitlab.com/dracks/swift-language-study"
							)
						}
						Div {
							Small(
								"Version: \(BuildInfo.version) (\(BuildInfo.gitCommit))"
							)
						}
						Div {
							Small("Jaume Singla Valls")
						}
					}.class("container")
				}
			}
		}
	}

	func htmx(_ content: Tag) -> Document {
		return Document(.html) {
			content
		}
	}

	func htmx(_ contents: [Tag]) -> Document {
		return Document(.html) {
			for content in contents {
				content
			}
		}
	}

	func paginate(metadata: PageMetadata) -> Tag {
		let currentPage = metadata.page
		let totalPages = metadata.pageCount
		var first = A("<<")
		var prev = A("<")
		var next = A(">")
		var last = A(">>")
		if currentPage > 1 {
			first = first.href("?page=1")
			prev = prev.href("?page=\(currentPage-1)")
		}

		if currentPage < totalPages {
			next = next.href("?page=\(currentPage+1)")
			last = last.href("?page=\(totalPages)")
		}
		return Nav {

			Li { first.role("button") }
			Li { prev.role("button") }
			for page in max(1, currentPage - 2)...min(totalPages, currentPage + 2) {
				Li {
					if page == currentPage {
						A(String(page)).role("button")
					} else {
						A(String(page)).href("?page=\(page)").role("button")
					}
				}
			}
			Li { next.role("button") }
			Li { last.role("button") }

		}
	}
}

let renderer = DocumentRenderer(minify: false, indent: 2)

extension Document: ResponseEncodable, AsyncResponseEncodable {

	public func render() -> String {
		return renderer.render(self)
	}

	public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
		var headers = HTTPHeaders()
		headers.add(name: .contentType, value: "text/html")
		return request.eventLoop.makeSucceededFuture(
			.init(
				status: .ok, headers: headers, body: .init(string: self.render())
			))
	}

	public func encodeResponse(for request: Request) async throws -> Response {
		var headers = HTTPHeaders()
		headers.add(name: .contentType, value: "text/html")
		return .init(status: .ok, headers: headers, body: .init(string: self.render()))
	}
}

extension Tag {
	public func role(_ role: String) -> Tag {
		return self.attribute("role", role)
	}
}

extension Tag {
	public func htmx(_ key: String, _ value: String) -> Tag {
		return self.attribute("hx-\(key)", value)
	}
}

class HomeTemplates: Templates {
	func home() -> Document {
		if let user = user {
			return layout(
				title: "Welcome back \(user.name ?? "")",
				content: Article {
					H2("Welcome back \(user.name ?? "")")
					H3("Exercices")
					Ul {
						Li {
							A("Show random words").href(
								"/exercises/random-words")
						}
					}
				})
		}
		return layout(
			title: "Welcome",
			content: Article {
				H2("Welcome to the swift language study project")
				H3("What is swift language study?")
				P(
					"Is a project made and dessigned to learn all possible declinations of language"
				)
				P(
					"With base on the german language, and his huge amount of declinations I decided to create some small project to make easy to study the words declinations randomly on base of the words from my classes book"
				)

			})

	}
}
