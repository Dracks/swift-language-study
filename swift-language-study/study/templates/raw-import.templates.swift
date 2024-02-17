import FluentKit
import Foundation
import SwiftHtml

extension Templates {
	func selectStudyLanguage(languages: [Language], selected: UUID? = nil) -> Select {
		return Select {
            Option("Select the language").value("")
			for language in languages {
				Option(language.name).value(language.id!.uuidString).selected(
					language.id == selected)
			}
		}
	}

	func seletctWordLevel(selected: WordLevel? = nil) -> Select {
		return Select {
            Option("Select word level").value("")
			for wordLevel in WordLevel.allCases {
				Option(wordLevel.rawValue).value(wordLevel.rawValue).selected(
					wordLevel == selected)
			}
		}
	}
}

class RawImportTemplates: Templates {
	func listRawWords(_ rawsList: Page<RawImport>, filterLevel wordLevel: WordLevel? = nil)
		-> Document
	{
		layout(
			title: "List Worlds",
			content: Article {
				Nav {
					Form {
						Ul {
							seletctWordLevel(selected: wordLevel).name(
								"level"
							).id("word-level")
						}
					}.method(.get).htmx("trigger", "change").htmx(
						"boost", "true")
					Ul {
						A("Import").href("import").role("button")
					}
				}
				Table {
					Tr {
						Th("Word")
						Th("Level")
						Th("Language")
					}
					for word in rawsList.items {
						Tr {
							Td(word.word)
							Td("\(word.level)")
							Td("\(word.language.name)")
						}
					}
				}
				paginate(metadata: rawsList.metadata)

			})
	}

	func inputRawForm(
		languages: [Language], language selectedLanguage: UUID? = nil,
		level wordLevel: WordLevel? = nil, words: String? = nil,
		errors: [String] = []
	) -> Document {
		layout(
			title: "Add new words",
			content: Article {
				Form {
					if !errors.isEmpty {
						Div {
							Ul {
								for error in errors {
									Li(error)
								}

							}
						}
					}

					Label("Select Language").for("language")
					selectStudyLanguage(
						languages: languages, selected: selectedLanguage
					).name("languageID")

					Label("Select the level").for("word-level")
					seletctWordLevel(selected: wordLevel).name("wordLevel")

					Label("Words (separated by comma)").for("words")
					Textarea(words).name("words").rows(5)
					Button("Submit").type(.submit).name("submit")
				}.method(.post).acceptCharset("utf-8")
			})
	}
}
