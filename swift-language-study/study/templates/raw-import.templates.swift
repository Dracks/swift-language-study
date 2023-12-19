import SwiftHtml

extension Templates {
    static func listRawWords() -> Document{
        layout(title: "List Worlds", content: Div{})
    }
    
    static func inputRawForm(languages: [String]) -> Document{
        layout(title: "Add new words", content: Main{
            
        })
    }
}
