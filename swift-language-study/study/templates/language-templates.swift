import SwiftHtml
import Vapor

class LanguageTemplates: Templates {
	func listLanguages(languages: [Language]) -> Document {
		return layout(
			title: "Languages",
			content: Main {
				Article {
					H1("Languages (\(languages.count))")
					Ul {
						for language in languages {
							Li {
								A(language.name).href(
									"/languages/\( language.id ?? UUID())"
								)
							}
						}
					}
					Form {
						H2("Add language")
						Form {
							input(
								type: .text, label: "Language",
								name: "name")
							Button("Add").type(.submit)
						}.method(.post)
					}.method(.post)
				}
			}.class("contents"))
	}

	func editLanguage(language: Language, error: String? = nil) -> Document {
		return layout(
			title: "Editing \(language.name)",
			content: Main {
				Article {
					H1("Editing \"\(language.name)\"")
					Form {
						input(
							type: .text, label: "Language",
							name: "name", value: language.name)
						Button("Save").type(.submit)
					}.method(.post)
				}
			})
	}
}
