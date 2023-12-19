
## Tables

```mermaidjs
classDiagram
class WordType {
    <<enumeration>>
    noun
    adjective
    verb
    pronoum
}

class WordLevel {
    <<enumeration>>
    A1
    A2
    B1
    B2
    C1
    C2
    D1
    D2
}
class Language {
    + name String
}

class RawImport {
    + word String
    + level WordLevel
}

class Word {
    + word String
    + level WordLevel
}


class Declination {
    + type WordType
    + person String
    + case String
}

class WordDeclination {
    + text String
}

class UserWord {
    + note String
    + shown int
    + right int
}

class User {
    + username String
}


RawImport "*" -- "1" Language
Word "*" -- "1" Language
WordDeclination "*" -- "1" Word
WordDeclination "1" -- "1" Declination
Language "1" -- "*" Declination

Word "1" -- "1" UserWord
UserWord "1" -- "1" User


```
