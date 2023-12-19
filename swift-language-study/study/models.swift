import Fluent
import Vapor

// Enumeration for WordType
enum WordType: String, Codable {
    case noun
    case adjective
    case verb
    case pronoun
}

// Enumeration for WordLevel
enum WordLevel: String, Codable {
    case A1
    case A2
    case B1
    case B2
    case C1
    case C2
    case D1
    case D2
}

// Language model
final class Language: Model {
    static let schema = "languages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

// RawImport model
final class RawImport: Model {
    static let schema = "rawImports"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "word")
    var word: String
    
    @Enum(key: "level")
    var level: WordLevel
    
    @Parent(key: "languageID")
    var language: Language
    
    init() {}
    
    init(id: UUID? = nil, word: String, level: WordLevel, languageID: UUID) {
        self.id = id
        self.word = word
        self.level = level
        self.$language.id = languageID
    }
}

// Word model
final class Word: Model {
    static let schema = "words"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "word")
    var word: String
    
    @Enum(key: "level")
    var level: WordLevel
    
    @Parent(key: "languageID")
    var language: Language
    
    init() {}
    
    init(id: UUID? = nil, word: String, level: WordLevel, languageID: UUID) {
        self.id = id
        self.word = word
        self.level = level
        self.$language.id = languageID
    }
}

// Declination model
final class Declination: Model {
    static let schema = "declinations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Enum(key: "type")
    var type: WordType
    
    @Field(key: "person")
    var person: String
    
    @Field(key: "case")
    var caseType: String
    
    init() {}
    
    init(id: UUID? = nil, type: WordType, person: String, caseType: String) {
        self.id = id
        self.type = type
        self.person = person
        self.caseType = caseType
    }
}

// WordDeclination model
final class WordDeclination: Model {
    static let schema = "wordDeclinations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "text")
    var text: String
    
    @Parent(key: "wordID")
    var word: Word
    
    init() {}
    
    init(id: UUID? = nil, text: String, wordID: UUID) {
        self.id = id
        self.text = text
        self.$word.id = wordID
    }
}
/*
// Relationships
extension RawImport {
    static let language = BelongsTo<RawImport, Language>(\.$language)
}

extension Word {
    static let language = BelongsTo<Word, Language>(\.$language)
}

extension WordDeclination {
    static let word = BelongsTo<WordDeclination, Word>(\.$word)
}

extension WordDeclination {
    static let declination = BelongsTo<WordDeclination, Declination>(\.$word)
}

extension Language {
    static let declinations = Children<Language, Declination>(\.$language)
}
*/
