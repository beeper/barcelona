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
`private enum CommandName: String, Codable {
    ${toChunk(enumInfo.map(([ name ]) => `case ${name}`))}
}

private var commandName: CommandName {
    switch self {
    ${toChunk(enumInfo.map(([ name ]) => `case .${name}(_): return .${name}`))}
    }
}

public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(commandName, forKey: .command)

    switch self {
    ${toChunk(enumInfo.map(([ name ]) => `case .${name}(let command):\n\ttry container.encode(command, forKey: .data)`))}
    }
}

public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let command = try container.decode(CommandName.self, forKey: .command)

    switch command {
    ${toChunk(enumInfo.map(([ name, container ]) => `case .${name}:\n\tself = .${name}(try container.decode(${container}.self, forKey: .data))`))}
    }
}`)
})