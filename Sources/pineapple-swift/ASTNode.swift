struct SourceCode {
    var lineNum: Int
    var statements: [Statement]
}

protocol Statement { }

struct Assignment: Statement {
    var lineNum: Int
    var variable: Variable
    var stringLiterial: String
}

struct Print: Statement {
    var lineNum: Int
    var variable: Variable
}

struct Variable {
    var lineNum: Int
    var name: String
}
