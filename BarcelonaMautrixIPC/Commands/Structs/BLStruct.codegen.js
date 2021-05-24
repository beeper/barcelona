const readline = require("readline");

function lines() {
    const interface = readline.createInterface(process.stdin);

    const lines = [];
    let finish;
    const promise = new Promise(resolve => finish = resolve);

    interface.on("line", line => {
        if (line.length === 0) {
            finish(lines);
            interface.close();
            return;
        }

        lines.push(line);
    });

    return promise;
}

function toChunk(lines) {
    return lines.join("\n    ");
}

lines().then(lines => {
    const enumInfo = lines.map(s => s.trim()).filter(s => s).map(s => s.split(" ")[1].split("(").map((s,i) => i == 0 ? s : s.substring(0, s.length - 1)));

    console.log(
`private enum BLStructName: String, Codable {
    ${toChunk(enumInfo.map(([ name ]) => `case ${name}`))}
}

private var structName: BLStructName {
    switch self {
    ${toChunk(enumInfo.map(([ name ]) => `case .${name}(_): return .${name}`))}
    }
}

public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
        
    try container.encode(structName, forKey: .type)
    
    switch self {
    ${toChunk(enumInfo.map(([ name ]) => `case .${name}(let object):\n\ttry object.encode(to: encoder)`))}
    }
}

public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
        
    let objectType = try container.decode(BLStructName.self, forKey: .type)
    
    switch objectType {
    ${toChunk(enumInfo.map(([ name, container ]) => `case .${name}:\n\tself = .${name}(try ${container}(from: decoder))`))}
    }
}
`)
});