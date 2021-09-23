import Foundation

enum LexerError: Error {
    case invalidSymbol
}

struct Lexer {
    // MARK: - public
    var sourceCode: String
    var lineNum = 0

    var nextToken: String?
    var nextTokenType: Token?
    var nextTokenLineNum: Int = 0

    init(sourceCode: String) {
        self.sourceCode = sourceCode
        lineNum = 1
        nextToken = ""
        nextTokenLineNum = 0
    }

    // MARK: - private
    // can add language keyword here
    private let keywords: [String: Token] = [
        "print": .print
    ]
}

extension Lexer {
    @discardableResult
    mutating func nextToken(is type: Token) -> (lineNum: Int, token: String) {
        let nextTokenInfo = try! getNextToken()

        if nextTokenInfo.tokenType != type {
            print("nextToken(is): syntax error near '\(nextTokenInfo.tokenType.rawValue)', expected token: \(type.rawValue) but got \(nextTokenInfo.tokenType.rawValue).")
        }

        return (nextTokenInfo.lineNum, nextTokenInfo.token)
    }

    mutating func lookAheadAndSkip(expectedType: Token) {
        let nowLineNum = lineNum
        let nextTokenInfo = try! getNextToken()

        // not is expected type, reverse cursor
        if nextTokenInfo.tokenType != expectedType {
            lineNum = nowLineNum
            nextTokenLineNum = nextTokenInfo.lineNum
            nextTokenType = nextTokenInfo.tokenType
            nextToken = nextTokenInfo.token
        }
    }

    mutating func lookAhead() -> Token {
        // nextToken already setted
        if nextTokenLineNum > 0 {
            return nextTokenType!
        }

        let nowLineNum = lineNum
        let nextTokenInfo = try! getNextToken()

        // not change lexing location, reverse cursor
        lineNum = nowLineNum
        nextTokenLineNum = nextTokenInfo.lineNum
        nextTokenType = nextTokenInfo.tokenType
        nextToken = nextTokenInfo.token

        return nextTokenInfo.tokenType
    }

    mutating func scanBeforeToken(token: String) -> String {
        guard let range = sourceCode.range(of: token) else {
            return ""
        }
        let prefixRange = sourceCode.startIndex..<range.lowerBound
        let prefix = sourceCode[prefixRange]
        let result = String(prefix)
        skipSourceCode(result.count)
        return result
    }
}

private extension Lexer {
    typealias TokenInfo = (lineNum: Int, tokenType: Token, token: String)

    mutating func getNextToken() throws -> TokenInfo {
        guard nextTokenLineNum <= 0 else {
            let lineNum = nextTokenLineNum
            let type = nextTokenType
            let token = nextToken

            self.lineNum = nextTokenLineNum
            nextTokenLineNum = 0
            return (lineNum, type!, token!)
        }
        return try matchToken()
    }

    mutating func matchToken() throws -> TokenInfo {
        // check ignored
        if isIgnored() {
            return (lineNum, Token.ignored, Token.ignored.rawValue)
        }

        // finish
        if sourceCode.isEmpty {
            return (lineNum, Token.eof, Token.eof.rawValue)
        }

        guard let firstChar = sourceCode.first else {
            throw LexerError.invalidSymbol
        }

        switch firstChar {
        case "$":
            skipSourceCode(1)
            return (lineNum, Token.varPrefix, "$")
        case "(":
            skipSourceCode(1)
            return (lineNum, Token.leftPren, "(")
        case ")":
            skipSourceCode(1)
            return (lineNum, Token.rightPren, ")")
        case "=":
            skipSourceCode(1)
            return (lineNum, Token.equal, "=")
        case #"""#:
            if nextSourceCode(is: #""""#) {
                skipSourceCode(2)
                return (lineNum, Token.dQuote, #""""#)
            } else {
                skipSourceCode(1)
                return (lineNum, Token.quote, #"""#)
            }
        default:
            // match name token
            if firstChar == "_" || isLetter(firstChar) {
                let token = scanName()
                if let keywordType = keywords[token] {
                    return (lineNum, keywordType, token)
                } else {
                    return (lineNum, Token.name, token)
                }
            }

            throw LexerError.invalidSymbol
        }
    }

    mutating func skipSourceCode(_ num: Int) {
        precondition(num >= 0)
        sourceCode.removeFirst(num)
    }

    func nextSourceCode(is value: String) -> Bool {
        return sourceCode.hasPrefix(value)
    }

    func isLetter(_ c: Character) -> Bool {
        "a"..."z" ~= c || "A"..."Z" ~= c
    }

    mutating func scanName() -> String {
        let regx = #"^[_\d\w]+"#
        return scan(regx: regx)
    }

    mutating func scan(regx: String) -> String {
        guard let range = sourceCode.range(of: regx, options: .regularExpression) else {
            return ""
        }
        let value = sourceCode[range]
        let result = String(value)
        skipSourceCode(result.count)
        return result
    }

    mutating func isIgnored() -> Bool {
        func isNewLine(_ c: Character) -> Bool {
            c == "\r" || c == "\n"
        }

        func isWhiteSpace(_ c: Character) -> Bool {
            switch c {
            case "\t", "\n", "\r", " ": // TODO: \v, \f
                return true
            default:
                return false
            }
        }

        var isIgnored = false
        while let firstChar = sourceCode.first {
            if nextSourceCode(is: "\r\n") || nextSourceCode(is: "\n\r") {
                skipSourceCode(2)
                lineNum += 1
                isIgnored = true
            } else if isNewLine(firstChar) {
                skipSourceCode(1)
                lineNum += 1
                isIgnored = true
            } else if isWhiteSpace(firstChar) {
                skipSourceCode(1)
                isIgnored = true
            } else {
                break
            }
        }

        return isIgnored
    }
}
