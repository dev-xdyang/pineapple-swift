enum ParserError: Error {
    case notString
    case unknownStatement
}

struct Parser {
    private var lexer: Lexer!
}

extension Parser {
    mutating func parse(code: String) -> SourceCode {
        lexer = Lexer(sourceCode: code)
        let sourceCode = parseSourceCode()
        lexer.nextToken(is: .eof)
        return sourceCode
    }
}

private extension Parser {
    // SourceCode ::= Statement+
    mutating func parseSourceCode() -> SourceCode {
        let lineNum = lexer.lineNum
        let statements = parseStatements()
        return SourceCode(lineNum: lineNum, statements: statements)
    }

    // Statement ::= Print | Assignment
    mutating func parseStatements() -> [Statement] {
        var statements: [Statement] = []

        while !isSourceCodeEnd(tokenType: lexer.lookAhead()) {
            guard let statement = try? parseStatement() else { break }
            statements.append(statement)
        }

        return statements
    }

    mutating func parseStatement() throws -> Statement {
        // skip if source code start with ignored token
        lexer.lookAheadAndSkip(expectedType: .ignored)

        switch lexer.lookAhead() {
        case .print:
            return parsePrint()
        case .varPrefix:
            return parseAssignment()
        default:
            throw ParserError.unknownStatement
        }
    }

    // Print ::= "print" "(" Ignored Variable Ignored ")" Ignored
    mutating func parsePrint() -> Print {
        let lineNum = lexer.lineNum
        lexer.nextToken(is: .print)
        lexer.nextToken(is: .leftPren)
        lexer.lookAheadAndSkip(expectedType: .ignored)
        let variable = parseVariable()
        lexer.lookAheadAndSkip(expectedType: .ignored)
        lexer.nextToken(is: .rightPren)
        lexer.lookAheadAndSkip(expectedType: .ignored)
        return Print(lineNum: lineNum, variable: variable)
    }

    // Assignment  ::= Variable Ignored "=" Ignored String Ignored
    mutating func parseAssignment() -> Assignment {
        let lineNum = lexer.lineNum
        let variable = parseVariable()
        lexer.lookAheadAndSkip(expectedType: .ignored)
        lexer.nextToken(is: .equal)
        lexer.nextToken(is: .ignored)

        let name = try! parseString()
        lexer.lookAheadAndSkip(expectedType: .ignored)
        let result = Assignment(lineNum: lineNum,
                                variable: variable,
                                stringLiterial: name)
        return result
    }

    mutating func parseName() -> String {
        let (_, name) = lexer.nextToken(is: .name)
        return name
    }

    // String ::= '"' '"' Ignored | '"' StringCharacter '"' Ignored
    mutating func parseString() throws -> String {
        var value = ""

        switch lexer.lookAhead() {
        case .dQuote:
            lexer.nextToken(is: .dQuote)
            lexer.lookAheadAndSkip(expectedType: .dQuote)
        case .quote:
            lexer.nextToken(is: .quote)
            value = lexer.scanBeforeToken(token: Token.quote.rawValue)
            lexer.nextToken(is: .quote)
            lexer.lookAheadAndSkip(expectedType: .ignored)
        default:
            print("parseString(): not a string.")
            throw ParserError.notString
        }
        
        return value
    }

    // Variable ::= "$" Name Ignored
    mutating func parseVariable() -> Variable {
        lexer.nextToken(is: .varPrefix)
        let name = parseName()
        let result = Variable(lineNum: lexer.lineNum, name: name)
        lexer.lookAheadAndSkip(expectedType: .ignored)
        return result
    }

    func isSourceCodeEnd(tokenType: Token) -> Bool {
        return tokenType == .eof
    }
}
