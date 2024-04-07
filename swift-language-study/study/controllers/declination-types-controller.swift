//
//  File.swift
//
//
//  Created by Singla Valls, Jaume on 29.12.23.
//

import Fluent
import SwiftHtml
import Vapor

struct DeclinationTypeController: RouteCollection {

	func boot(routes: RoutesBuilder) throws {
		let declinationsTypeRoute = routes.grouped("declinations-form").grouped([
			UserIdentifiedMiddleware(), AdminMiddleware(),
		])
		// rawImportsRoute.get(use: listFiltered)
		declinationsTypeRoute.get("edit", use: createTypeForm)
		declinationsTypeRoute.get("select-type", use: selectDecTypesForm)
		declinationsTypeRoute.post("select-type", use: selectOrCreateTypesForm(req:))
		declinationsTypeRoute.post("new-type", use: createDecType)
		declinationsTypeRoute.post("new-case", use: createDecCase)
		declinationsTypeRoute.put("case", ":case-id", ":movement", use: moveDecCase)
		declinationsTypeRoute.delete("case", ":case-id", use: dropDecCase)
	}

	func createTypeForm(req: Request) async throws -> Document {
		let languages = try await Language.query(on: req.db).all()
		return DeclinationTypesTemplates(req: req).createDeclinationTypeBase(
			languages: languages)
	}

	func selectDecTypesForm(req: Request) async throws -> Document {
		let language: String = try req.query.get(at: "language")
		guard let language = UUID(uuidString: language) else {
			return try await createTypeForm(req: req)
		}
		let decTypes = try await DeclinationType.query(on: req.db).filter(
			\.$language.$id == language
		)
		.all()

		return DeclinationTypesTemplates(req: req).createDeclinationTypeSelectType(
			languageId: language, types: decTypes)
	}

	func selectOrCreateTypesForm(req: Request) async throws -> Document {
		let language: UUID = try req.content.get(at: "language")
		let type: String = try req.content.get(at: "dec-type")
		let templates = DeclinationTypesTemplates(req: req)
		if type == "-- new-type --" {
			return templates.createDeclinationTypeCreateTypeForm(languageId: language)
		}
		guard let typeId = UUID(uuidString: type) else {
			throw Abort(.badRequest)
		}
		let decCases =
			try await DeclinationTypeCase
			.query(on: req.db)
			.filter(\.$type.$id == typeId)
			.sort(\.$order, .ascending)
			.all()
		let decTypes = try await DeclinationType.query(on: req.db)
			.filter(\.$language.$id == language)
			.sort(\.$order, .ascending)
			.all()

		return templates.newDeclinationTypeCreatedWithDeclinationsForm(
			languageId: language, decType: typeId, types: decTypes, cases: decCases)
	}

	func createDecType(req: Request) async throws -> Document {
		let language: UUID = try req.content.get(at: "language")
		let decTypeName: String = try req.content.get(at: "name")

		let decTypesCount = try await DeclinationType.query(on: req.db).filter(
			\.$language.$id == language
		).count()

		let type = DeclinationType(
			name: decTypeName, order: decTypesCount, languageID: language)
		try await type.save(on: req.db)

		let decTypes = try await DeclinationType.query(on: req.db).filter(
			\.$language.$id == language
		)
		.all()
		return DeclinationTypesTemplates(req: req)
			.newDeclinationTypeCreatedWithDeclinationsForm(
				languageId: language, decType: type.id!, types: decTypes, cases: [])
	}

	func createDecCase(req: Request) async throws -> Document {
		let decTypeId: UUID = try req.content.get(at: "dec-type")
		let caseName: String = try req.content.get(at: "name")

		let decCaseCount = try await DeclinationTypeCase.query(on: req.db).filter(
			\.$type.$id == decTypeId
		).count()

		let decCase = DeclinationTypeCase(
			typeId: decTypeId, name: caseName, order: decCaseCount)
		try await decCase.save(on: req.db)

		let decCases = try await DeclinationTypeCase.query(on: req.db).filter(
			\.$type.$id == decTypeId
		)
		.sort(\.$order, .ascending).all()

		return DeclinationTypesTemplates(req: req).createDeclinationsCaseForm(
			decType: decTypeId, cases: decCases)
	}

	func dropDecCase(req: Request) async throws -> Document {
		let decCaseIdStr = req.parameters.get("case-id") ?? ""
		let decTypeId: UUID = try req.content.get(at: "dec-type-id")
		let templates = DeclinationTypesTemplates(req: req)

		if let decCaseId = UUID(uuidString: decCaseIdStr) {
			let decCase = try await DeclinationTypeCase.query(on: req.db).filter(
				\.$id == decCaseId
			)
			.first()
			if let decCase = decCase {
				if decCase.$type.id == decTypeId {
					var order = decCase.order
					try await decCase.delete(on: req.db)
					let afterDecCases = try await DeclinationTypeCase.query(
						on: req.db
					).filter(
						\.$type.$id == decTypeId
					).filter(\.$order > order).sort(\.$order, .ascending).all()
					for afterDecCase in afterDecCases {
						let newOrder = try await DeclinationTypeCase.query(
							on: req.db
						).filter(
							\.$type.$id == decTypeId
						).filter(\.$order < order).count()
						afterDecCase.order = newOrder
						try await afterDecCase.save(on: req.db)
						order = newOrder
					}
				}
			}
		}
		let cases = try await DeclinationTypeCase.query(on: req.db).filter(
			\.$type.$id == decTypeId
		)
		.sort(\.$order, .ascending).all()
		return templates.declinationsCaseList(cases: cases, decTypeId: decTypeId)
	}
	func moveDecCase(req: Request) async throws -> Document {
		let decCaseIdStr = req.parameters.get("case-id") ?? ""

		let moveStr = req.parameters.get("movement") ?? "0"

		let decTypeId: UUID = try req.content.get(at: "dec-type-id")
		let templates = DeclinationTypesTemplates(req: req)

		if let decCaseId = UUID(uuidString: decCaseIdStr), let move: Int = Int(moveStr) {

			let decCase = try await DeclinationTypeCase.query(on: req.db).filter(
				\.$id == decCaseId
			)
			.first()
			if let decCase = decCase {
				if decCase.$type.id == decTypeId {
					var newOrder = decCase.order + move
					let maxOrder = try await DeclinationTypeCase.query(
						on: req.db
					).filter(\.$type.$id == decTypeId).count()
					if newOrder < 0 {
						newOrder = 0
					} else if newOrder >= maxOrder {
						newOrder = maxOrder - 1
					}
					if newOrder != decCase.order {
						let isMoveUp = decCase.order > newOrder
						var decCasesToMoveQuery = DeclinationTypeCase.query(
							on: req.db
						).filter(\.$type.$id == decTypeId)
						if isMoveUp {
							decCasesToMoveQuery =
								decCasesToMoveQuery.filter(
									\.$order >= newOrder
								).filter(\.$order < decCase.order)
						} else {
							decCasesToMoveQuery =
								decCasesToMoveQuery.filter(
									\.$order <= newOrder
								).filter(\.$order > decCase.order)
						}
						let decCasesToMove =
							try await decCasesToMoveQuery.sort(
								\.$order, .ascending
							).all()

						decCase.order = newOrder
						try await decCase.save(on: req.db)

						for decCaseToMove in decCasesToMove {
							var countQuery = DeclinationTypeCase.query(
								on: req.db
							).filter(\.$type.$id == decTypeId).filter(
								\.$id != decCaseToMove.id!)
							if isMoveUp {
								countQuery = countQuery.filter(
									\.$order
										<= decCaseToMove
										.order)
							} else {
								countQuery = countQuery.filter(
									\.$order
										< decCaseToMove
										.order)
							}
							decCaseToMove.order =
								try await countQuery.count()
							try await decCaseToMove.save(on: req.db)
						}
					}
				}
			}
		}

		let cases = try await DeclinationTypeCase.query(on: req.db).filter(
			\.$type.$id == decTypeId
		)
		.sort(\.$order, .ascending).all()
		return templates.declinationsCaseList(cases: cases, decTypeId: decTypeId)
	}

}
