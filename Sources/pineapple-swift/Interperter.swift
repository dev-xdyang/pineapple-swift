enum InterpreterError: Error {
    case astError
    case variableNotExist
}

struct Interpreter {
    private var variables = ["": ""]

    mutating func execute(code: String) throws {
        var parser = Parser()
        let ast = parser.parse(code: code)
        try resolve(ast: ast)
    }
}

private extension Interpreter {
    mutating func resolve(ast: SourceCode) throws {
        guard !ast.statements.isEmpty else {
            throw InterpreterError.astError
        }
        try ast.statements.forEach {
            try resolve(statement: $0)
        }
    }

    mutating func resolve(statement: Statement) throws {
        if let print = statement as? Print {
            try resolve(print: print)
        } else if let assignment = statement as? Assignment {
            resolve(assignment: assignment)
        }
    }

    mutating func resolve(assignment: Assignment) {
        let varName = assignment.variable.name
        variables[varName] = assignment.stringLiterial
    }

    func resolve(print: Print) throws {
        let varName = print.variable.name
        guard let value = variables[varName] else {
            throw InterpreterError.variableNotExist
        }
        Swift.print(value)
    }
}
