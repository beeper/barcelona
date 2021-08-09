const fs = require("fs");

function toChunk(lines) {
    return lines.join("\n    ");
}

function arg(key) {
    const index = process.argv.indexOf(key);
    if (index === -1) return null;
    return process.argv[index + 1];
}

const src = arg("--src");
const enumName = arg("--name") || src.split("/").reverse()[0].split(".")[0];
const out = arg("--out") || enumName + "+Codable.swift";

if (!src) throw new Error("--src is required");
if (!out) throw new Error("--out is required");
if (!enumName) throw new Error("--name is required");

let idKey = arg("--id-key");
let payloadKey = arg("--payload-key");

if (fs.existsSync(out)) {
    const state = fs.readFileSync(out).toString("utf8").split("\n")[0];

    if (state.startsWith("/*bmi ") && state.endsWith(" bmi*/")) {
        const recoveredState = JSON.parse(state.slice("/* bmi ".length - 1, -" bmi*/".length))

        idKey = idKey || recoveredState.idKey;
        payloadKey = payloadKey || recoveredState.payloadKey;
    }
}

if (!idKey) throw new Error("--id-key is required");
if (!payloadKey) throw new Error("--payload-key is required");

function extractCases(filename, enumName) {
    const text = fs.readFileSync(filename).toString("utf8");
    
    let lines = text.split("\n");

    const start = lines.findIndex(line => line.includes(`enum ${enumName}`));

    lines = lines.slice(start + 1);

    const end = lines.findIndex(line => line === "}");

    lines = lines.slice(0, end).map(line => line.trim()).filter(line => line.startsWith("case "));

    return lines;
}

/** @param {string[]} cases @returns {{name:string;type:string;flags:string[];}[]} */
function parseCases(cases) {
    return cases.map(caze => caze.slice("case ".length)).map(rawCase => {
        const parenBegin = rawCase.indexOf("(");
        const parenEnd = rawCase.indexOf(")");

        const flagBegin = rawCase.indexOf("/*");
        const flagEnd = rawCase.indexOf("*/");

        const name = rawCase.slice(0, parenBegin);
        const type = rawCase.slice(parenBegin + 1, parenEnd);
        let flags = [];

        if (flagBegin > -1 && flagEnd > -1) {
            const rawFlags = rawCase.slice(flagBegin + 2, flagEnd);
            flags = rawFlags.split(" ").filter(l => l);
        }

        return {
            name,
            type,
            flags
        }
    })
}

const cases = parseCases(extractCases(src, enumName));

const enumIDTypeName = `${enumName}Name`

function swiftCase(name, code) {
    return `\tcase .${name}:\n\t\t\t${code}`
}

function swiftVCase(name, code) {
    return `\tcase .${name}(let ${payloadKey}):\n\t\t\t${code}`
}

function swiftSwitch(variable, cases) {
    return `switch ${variable} {
    ${toChunk(cases)}
        }`
}

function generateDecodableStatement({ name, type: container, flags }) {
    if (flags.includes("bmi-no-decode")) return swiftCase(name, `fatalError("${name} cannot be decoded (yet)")`)
    else return swiftCase(name, `self = .${name}(try container.decode(${container}.self, forKey: .${payloadKey}))`)
}

function generateEncodableStatement({ name, flags }) {
    if (flags.includes("bmi-no-encode")) return swiftCase(name, `fatalError("${name} cannot be encoded (yet)")`)
    else return swiftVCase(name, `try container.encode(${payloadKey}, forKey: .${payloadKey})`)
}

fs.writeFileSync(out,
`/*bmi ${JSON.stringify({ idKey, payloadKey })} bmi*/

extension ${enumName}: Codable {
    public enum ${enumIDTypeName}: String, Codable {
    ${toChunk(cases.map(({ name }) => `\tcase ${name}`))}
    }
    
    private enum CodingKeys: CodingKey, CaseIterable {
        case ${idKey}
        case ${payloadKey}
    }

    public var name: ${enumIDTypeName} {
        ${swiftSwitch("self", cases.map(({ name }) => swiftCase(name, `return .${name}`)))}
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .${idKey})

        ${swiftSwitch("self", cases.map(generateEncodableStatement))}
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let ${idKey} = try container.decode(${enumIDTypeName}.self, forKey: .${idKey})

        ${swiftSwitch("command", cases.map(generateDecodableStatement))}
    }
}`
)