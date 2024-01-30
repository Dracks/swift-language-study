import FluentKit
import SwiftHtml
import Vapor

class WordsManagementTemplates: Templates {
	private func selectWordType(_ type: WordType?) -> Select {
		// Todo select word type from word
		return Select {
			Option("Select type")
			Option("Article").value(WordType.article.rawValue).selected(
				type == .article)
			Option("Adjective").value(WordType.adjective.rawValue).selected(
				type == .adjective)
			Option("Noun").value(WordType.noun.rawValue).selected(type == .noun)
			Option("Pronoun").value(WordType.pronoun.rawValue).selected(
				type == .pronoun)
			Option("Verb").value(WordType.verb.rawValue).selected(type == .verb)
		}
	}
	private func rawWordControls(language: Language) -> Tag {
		return Div {
			A("Search Raw Word").role("button")
			Span("Select unassigned Raw Word")
				.role("button")
				.htmx(
					"get",
					"/words-management/select-raw-import/random/\(language.id?.uuidString ?? "")"
				)
				.htmx("target", "#raw-import-word")
				.htmx("swap", "outerHTML")
			A("Delete word").role("button")
		}
	}
	private func emptyRaw(language: Language) -> Tag {
		return Div {
			rawWordControls(language: language).class("grid")
		}.id("raw-import-word")
	}

	private func wordForm(
		_ word: Word? = nil,
		wordLevel: WordLevel? = nil
	) -> Tag {
		var postUrl = "/words-management/new-word"
		if let wordId = word?.id {
			postUrl = "/words-management/word/\(wordId)"
		}
		return Form {
			Input().name("wordId").value(word?.id?.uuidString).type(.hidden)
			input(
				type: .text, label: "Word:", name: "word", value: word?.word ?? "",
				required: true)
			seletctWordLevel(selected: wordLevel ?? word?.level).name("wordLevel").id(
				"wordLevel")
			// Submit on change, regenerating this with the ID,
			// then can get a multiple form, with the matrix, for every declination
			selectWordType(word?.type).name("wordType").id("wordType").required()
			Button("Save and complete").type(.submit)
		}.id("wordForm")
			.htmx("post", postUrl)
	}

	func listWords(words wordsPage: Page<Word>) -> Document {
		return layout(
			title: "Words list",
			content: Article {
				Nav {
					Ul {
						A("New word").href("new-word").role("button")
					}
				}
				Table {
					Tr {
						Th("Word")
						Th("Type")
						Th("Level")
						Th("Language")
					}
					for word in wordsPage.items {
						Tr {
							Td(word.word)
							Td(word.type.rawValue)
							Td(word.level?.rawValue)
							Td(word.language.name)
							Td {
								A("edit").href(
									"/words-management/edit-word/\(word.id?.uuidString ?? "")"
								)
							}
						}
					}
				}
				paginate(metadata: wordsPage.metadata)
			})
	}

	func createWordForm(languages: [Language]) -> Document {
		return layout(
			title: "New word",
			content: Article {
				Div {
					H1("New Word")
					Label("Select language").for("languageId")
					selectStudyLanguage(languages: languages)
						.name("languageId")
						.class("extra-fields")
						.htmx("get", "/words-management/get-form")
						.htmx("target", "#full-word")
					Div().id("full-word")
				}
			}.class("grid"))
	}

	func getWordForm(language: Language, andWord word: Word? = nil) -> Document {
		return htmx([
			emptyRaw(language: language),
			wordForm(word).htmx("include", ".extra-fields"),

			Div().id("declinations-table"),
		])
	}

	func selectRawImportForm(word: RawImport, forLanguage language: Language) -> Document {
		return htmx([
			Div {
				Input().name("rawWordId").type(.hidden).value(word.id?.uuidString)
					.class("extra-fields")
				Label().for("raw-word")
				Span(word.word).attribute("name", "raw-word")
				rawWordControls(language: language).class("grid")
			}.id("raw-import-word"),
			wordForm(wordLevel: word.level).htmx("include", ".extra-fields").htmx(
				"swap-oob", "true"),
		])
	}

	func emptyRawImportForm(language: Language) -> Document {
		return htmx(emptyRaw(language: language))
	}

	func renderDecForm(
		declination current: WordDeclination?, wordId: UUID?,
		forDeclinations declinations: [DeclinationTypeCase]
	) -> Tag {
		return Form {
			for declination in declinations {
				Input().type(.hidden).name("declinationTypeIds[]").value(
					declination.id?.uuidString)

			}
			if let current = current {
				Input().type(.hidden).name("declinationId").value(
					current.id?.uuidString)
			}
			Input().type(.hidden).name("wordId").value(wordId?.uuidString)
			Input().name("declination").value(current?.text ?? "")
		}.htmx("post", "/words-management/edit-declination")
			.htmx("swap", "outerHTML")
			.htmx("trigger", "change")
	}

	func renderDecForm(
		word: Word,
		forDeclinations declinations: [DeclinationTypeCase]
	) -> Tag {

		let decIds = Set(declinations.map { $0.id })

		let current = word.declinations.filter { dec in
			let decCaseIds = Set(dec.declinationCase.map { $0.id })
			return decCaseIds.isSubset(of: decIds)
		}.first
		return renderDecForm(
			declination: current, wordId: word.id, forDeclinations: declinations)
	}

	func renderDeclinationForms(
		word: Word, firstDeclination vertical: DeclinationType,
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
						Td {
							renderDecForm(
								word: word,
								forDeclinations: [
									vertCase, horCase,
								])
						}
					}
				}
			}
		}
	}

	func renderDeclinationForms(word: Word, firstDeclination declination: DeclinationType)
		-> Tag
	{

		return Table {

			Tr {
				Th()

			}
			for vertCase in declination.cases {
				Tr {
					Th(vertCase.name)

					Td {
						renderDecForm(
							word: word, forDeclinations: [vertCase])
					}
				}
			}
		}
	}

	func renderDeclinationForms(word: Word, declinations declinationsTypes: [DeclinationType])
		-> Tag
	{
		if declinationsTypes.count == 1 {
			return renderDeclinationForms(
				word: word, firstDeclination: declinationsTypes.first!)
		} else if declinationsTypes.count == 2 {
			return renderDeclinationForms(
				word: word, firstDeclination: declinationsTypes.first!,
				secondDeclination: declinationsTypes.last!)
		}
		return Div(
			"Unsoported declinations configuration for this kind of word")
	}

	func partialEditWord(word: Word, withDeclinations declinationsTypes: [DeclinationType])
		-> Document
	{
		return htmx([
			wordForm(word),
			renderDeclinationForms(word: word, declinations: declinationsTypes),
		])
	}

	func editWordForm(word: Word, withDeclinations declinationsTypes: [DeclinationType])
		-> Document
	{
		return layout(
			title: "Edit '\(word.word)",
			content: Article {
				wordForm(word)
				renderDeclinationForms(word: word, declinations: declinationsTypes)
			})
	}

	func partialEditDeclinationForm(
		declination: WordDeclination?, wordId: UUID,
		withDeclinations declinationstypes: [DeclinationTypeCase]
	) -> Document {
		return htmx(
			renderDecForm(
				declination: declination, wordId: wordId,
				forDeclinations: declinationstypes))
	}
}
