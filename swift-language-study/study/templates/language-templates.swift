import SwiftHtml
import Vapor

extension Templates {
    static func listLanguages(languages: [Language]) -> Document {
        return layout(title: "Languages", content: Main{
            Article{
                H1("Languages (\(languages.count))")
                Ul{
                    for language in languages {
                        Li{
                            A(language.name).href("/languages/\( language.id ?? UUID())")
                        }
                    }
                }
                Form{
                    H2("Add language")
                    
                }.method(.post)
            }
        }.class("contents"))
    }
}
