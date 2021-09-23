import  Foundation

let args = CommandLine.arguments
guard args.count == 2 else {
    let cmd = URL(string: args.first!)?.lastPathComponent
    print("Usage: \(cmd ?? "") filename\n")
    exit(EXIT_FAILURE)
}

let fileName = args[1]
var filePath = URL(string: #file)
// the cmd not at root directory
for _ in 0..<3 {
    filePath?.deleteLastPathComponent()
}
filePath?.appendPathComponent(fileName)

guard let path = filePath?.absoluteString,
      FileManager.default.fileExists(atPath: path) else {
    let path = filePath?.absoluteString ?? ""
    print("\(fileName) is not exist at \(path)")
    exit(EXIT_FAILURE)
}

do {
    let code = try String(contentsOfFile: path)
    var interpreter = Interpreter()
    try interpreter.execute(code: code)
} catch {
    print("read code error: \(error)")
}



