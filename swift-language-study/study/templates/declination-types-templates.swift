//
//  File.swift
//
//
//  Created by Singla Valls, Jaume on 29.12.23.
//

import SwiftHtml
import Vapor

func listCaseWithControls(cases: [DeclinationTypeCase], decTypeId: UUID) -> Tag {
	Ul {
		Span("Existing cases")
		Input().type(.hidden).name("dec-type-id").value(decTypeId.uuidString)
		Ul {
			for decCase in cases {
				Li {
					Span().class("fa fa-arrow-up", "secondary").role("button")
						.htmx(
							"put",
							"/declinations-form/case/\(decCase.id?.uuidString ?? "---")/-1"
						)
						.htmx("target", "#cases-list")
						.htmx("include", "[name='dec-type-id']")
					Span().class("fa fa-arrow-down", "secondary").role("button")
						.htmx(
							"put",
							"/declinations-form/case/\(decCase.id?.uuidString ?? "---")/1"
						)
						.htmx("target", "#cases-list")
						.htmx("include", "[name='dec-type-id']")
					Span().class("fa fa-trash", "danger").role("button")
						.htmx(
							"delete",
							"/declinations-form/case/\(decCase.id?.uuidString ?? "---")"
						)
						.htmx("target", "#cases-list")
						.htmx("include", "[name='dec-type-id']")
					Span(decCase.name)

				}
			}
		}
	}.htmx("target", "#cases-list")
}

func caseForm(decType: UUID) -> Tag {
	return Form {
		Input().type(.hidden).name("dec-type").value(decType.uuidString)
		Label("Declination name").for("name")
		Input().type(.text).name("name")
		Button("Save").type(.submit)
	}.htmx("post", "/declinations-form/new-case").htmx("target", "#cases-form")
}

func selectDeclinationTypeForm(languageId: UUID, types: [DeclinationType], selected: UUID? = nil)
	-> Tag
{
	return
		Form {
			Input().type(.hidden).name("language").value(languageId.uuidString)
			Label("Select declination type").for("dec-type")
			Select {
				Option("Select type")
				for type in types {
					Option(type.name).value(type.id?.uuidString ?? "").selected(
						selected == type.id)
				}
				Option("New type").value("-- new-type --")
			}.name("dec-type").id("dec-type")
		}
		.attribute("hx-trigger", "change from:#dec-type")
		.attribute("hx-post", "/declinations-form/select-type")
		.attribute("hx-target", "#select-type")
		.attribute("hx-select", "#select-type-form")
}

extension Templates {
	func createDeclinationTypeBase(languages: [Language]) -> Document {
		return layout(
			title: "New declination type",
			content: Article {
				H1("New declination type")
				Label("Select language").for("language")
				Select {
					Option("Select language").value("").selected()
					for language in languages {
						Option(language.name).value(
							language.id?.uuidString ?? "")
					}
				}.name("language").attribute(
					"hx-get", "/declinations-form/select-type"
				).attribute(
					"hx-target", "#select-type"
				)
				.attribute("hx-select", "#select-type-form")
				Div {

				}.id("select-type")
				Div {

				}.id("cases-form")
				Div {

				}.id("cases-list")
			})
	}

	func createDeclinationTypeSelectType(
		languageId: UUID, types: [DeclinationType], selected: UUID? = nil
	) -> Document {
		return htmx(
			[
				selectDeclinationTypeForm(
					languageId: languageId, types: types, selected: selected
				)
				.id("select-type-form"),
				Span().htmx("swap-oob", "innerHTML:#cases"),
			]
		)
	}

	func createDeclinationTypeCreateTypeForm(languageId: UUID) -> Document {
		return htmx(
			Form {
				Input().type(.hidden).name("language").value(languageId.uuidString)
				Label("Enter the new declination type name").for("name")
				Input().type(.text).name("name")
				Button("Save").type(.submit)
			}
			.attribute("hx-target", "#select-type")
			.attribute("hx-select", "#select-type-form")
			.attribute("hx-post", "/declinations-form/new-type")
			.id("select-type-form")
		)
	}

	func newDeclinationTypeCreatedWithDeclinationsForm(
		languageId: UUID, decType: UUID, types: [DeclinationType],
		cases: [DeclinationTypeCase]
	) -> Document {
		return htmx(
			Div {
				selectDeclinationTypeForm(
					languageId: languageId, types: types, selected: decType
				).id(
					"select-type-form")
				caseForm(decType: decType).htmx(
					"swap-oob", "innerHTML:#cases-form")
				listCaseWithControls(cases: cases, decTypeId: decType).htmx(
					"swap-oob", "innerHTML:#cases-list")
			})
	}

	func createDeclinationsCaseForm(decType: UUID, cases: [DeclinationTypeCase]) -> Document {
		return htmx([
			caseForm(decType: decType),
			listCaseWithControls(cases: cases, decTypeId: decType).htmx(
				"swap-oob", "innerHTML#cases-list"),
		])
	}

	func declinationsCaseList(cases: [DeclinationTypeCase], decTypeId: UUID) -> Document {
		return htmx(
			listCaseWithControls(cases: cases, decTypeId: decTypeId)
		)
	}
}
