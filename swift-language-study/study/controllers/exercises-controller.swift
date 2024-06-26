import Fluent
import SwiftHtml
import Vapor

class ExercisesController: RouteCollection {

	struct RandomWordQuery: Content {
		var language: UUID
		var level: WordLevel?
		var type: WordType?

		init(from decoder: Decoder) throws {
			let container:
				KeyedDecodingContainer<
					ExercisesController.RandomWordQuery.CodingKeys
				> = try decoder.container(
					keyedBy: ExercisesController.RandomWordQuery.CodingKeys.self
				)
			self.language = try container.decode(
				UUID.self,
				forKey: ExercisesController.RandomWordQuery.CodingKeys.language)
			let levelString = try container.decodeIfPresent(String.self, forKey: .level)
			if let levelString = levelString {
				if !levelString.isEmpty {
					self.level = try container.decode(
						WordLevel.self, forKey: .level)
				}
			}
			let typeString = try container.decodeIfPresent(String.self, forKey: .type)
			if let typeString = typeString {
				if !typeString.isEmpty {
					self.type = try container.decode(
						WordType.self, forKey: .type)
				}
			}
		}
		init(language: UUID, level: WordLevel? = nil, type: WordType? = nil) {
			self.language = language
			self.level = level
			self.type = type
		}
	}
	func boot(routes: RoutesBuilder) throws {
		let exercisesRoute = routes.grouped("exercises").grouped([
			UserIdentifiedMiddleware()
		])
		exercisesRoute.get("random-words", use: getFilterRandom)
		exercisesRoute.post("random-words", use: nextRandomWord)
	}

	func getFilterRandom(req: Request) async throws -> Document {
		let languages = try await Language.query(on: req.db).all()
		return ExercisesTemplates(req: req).filterRandomWords(languages)
	}

	func nextRandomWord(req: Request) async throws -> Document {
		let templates = ExercisesTemplates(req: req)

		let data = try req.content.decode(RandomWordQuery.self)

		var dbQuery = Word.query(on: req.db).filter(\.$language.$id == data.language)

		if let wordLevel = data.level {
			dbQuery = dbQuery.filter(\.$level == wordLevel)
		}

		if let wordType = data.type {
			dbQuery = dbQuery.filter(\.$type == wordType)
		}

		let word = try await dbQuery.with(\.$declinations) { dec in
			dec.with(\.$declinationCase)

		}.sort(.custom("random()")).first()

		guard let word = word else {
			// todo: use a custom not-found to show how to add new words
			return templates.notFound()
		}

		let wordTypeDeclinations = try await WordTypeDeclination.getInfo(
			on: req.db, forType: word.type, andLanguage: word.$language.id)

		let declinations = try wordTypeDeclinations.map { wordTypeDec in
			try wordTypeDec.requireID().declinationType
		}

		return templates.viewRandomWord(
			word, withDeclinations: declinations, forQuery: data)

	}
}
