enum Token: String {
    case eof = "EOF"
    case varPrefix = "$"
    case leftPren = "("
    case rightPren = ")"
    case equal = "="
    case quote = #"""#
    case dQuote = #""""#
    case name = "Name"    // Name ::= [_A-Za-z][_0-9A-Za-z]*
    case print = "print"
    case ignored = "Ignored"
}
