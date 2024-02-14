import FluentKit
import SwiftHtml
import Vapor

class ExercisesTemplates: Templates {
	func filterRandomWords(_ languages: [Language]) -> Document {
		return layout(
			title: "Select the random words filters",
			content:
				Article {
					Form {
						H2("Jumb between random words")
						Label("Select language")
						selectStudyLanguage(languages: languages).name(
							"language"
						).required()
						Label("Select level")
						seletctWordLevel().name("level")
						Label("Select type")
						selectWordType().name("type")
						Button("Start")
					}.htmx("post", "/exercises/random-words")
				}.class("medium-form")
		)
	}

	func renderWord(_ word: Word, withFirstDeclination declination: DeclinationType) -> Tag {
		return Table {

			Tr {
				Th()

			}
			for vertCase in declination.cases {
				Tr {
					Th(vertCase.name)

					Td(word.selectDeclination(match: [vertCase])?.text ?? "")
				}
			}
		}
	}

	func renderWord(
		_ word: Word, withFirstDeclination vertical: DeclinationType,
		secondDeclination horizontal: DeclinationType
	) -> Tag {
		return Table {
			Tr {
				Th()
				for horCase in horizontal.cases {
					Th(horCase.name)
				}
			}
			for vertCase in vertical.cases {
				Tr {
					Th(vertCase.name)
					for horCase in horizontal.cases {
						Td(
							word.selectDeclination(match: [
								horCase, vertCase,
							])?.text ?? "")
					}
				}
			}
		}

	}

	func renderDeclinations(_ declinations: [DeclinationType], forWord word: Word) -> Tag {
		if declinations.count == 1 {
			return renderWord(word, withFirstDeclination: declinations.first!)
		} else if declinations.count == 2 {
			return renderWord(
				word, withFirstDeclination: declinations.first!,
				secondDeclination: declinations.last!)
		}
		return Div("Unsoported declinations configuration for this kind of word")
	}

	func viewRandomWord(
		_ word: Word, withDeclinations declinations: [DeclinationType],
		forQuery query: ExercisesController.RandomWordQuery
	) -> Document {
		return htmx([
			Form {
				H3(word.word)
				renderDeclinations(declinations, forWord: word)
				Input().type(.hidden).name("language").value(
					query.language.uuidString)
				Input().type(.hidden).name("level").value(
					query.wordLevel?.rawValue ?? "")
				Input().type(.hidden).name("type").value(
					query.wordType?.rawValue ?? "")
				Button("Next")
			}.htmx("post", "/exercises/random-words")
		])
	}
}
