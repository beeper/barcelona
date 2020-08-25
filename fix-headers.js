const fs = require("fs");
const path = require("path");
const { isRegExp } = require("util");

function fixArrowImports(line) {
    let regex = /#import <([\w-]+.h)>/g;
    let match = regex.exec(line);
    if (!match) return line;
    return `#import "${match[1]}"`
}

function fixNSImports(line) {
    let regex = /#import "NS\w+.h"/g;
    let match = regex.exec(line);
    if (!match) return line;
    return `#import <Foundation/Foundation.h>`
}

function fixIgnoredLines(line) {
    switch (line) {
        case "- (void).cxx_destruct;":
            return "";
        default:
            return line;
    }
}

function fixCDUnknownBlockType(line) {
    return line.replace(/CDUnknownBlockType/g, "id").replace(/CDUnknownFunctionPointerType/g, "id");
}

function fixCNCancelable(line) {
    return line.replace(/<CNCancelable>/g, "");
}

function fixMistypedHash(line) {
    return line.replace(/unsigned long long hash/g, "unsigned long hash");
}

function fixNSObjectParameterization(line) {
    return line.replace(/NSObject\s?<.*>/g, "NSObject").replace(/(@protocol\s[\w\d_]+)\s<NSObject>/g, '$1');
}

function fixIDParameterization(line) {
    return line.replace(/id\s?<.*>/g, "id")
}

function fixFakeShit(line) {
    return line.replace(/CDStruct(?:_\w+)?(?:\s\*)?/g, "id ")
}

function fixIDPointer(line) {
    return line.replace(/\bid\s?\*/g, "id ");
}

function fixBrokenStruct(line) {
    return line.replace(/:\(struct \w+\s\[\d+\]\)/g, ":(id)");
}

function fixFailParse(line) {
    return line.replace(/.*\/\/\sError\sparsing\stype.*/g, "");
}

function fixCDStruct(line) {
    return line.replace(/:\(CDStruct_[\d\w]+\s?\*?\)/g, ":(id)").replace(/.*\bCDStruct_[\d\w]+\s[\d\w]+;/g, "");
}

function fixPBCodable(line) {
    return line.replace(/#import "PBCodable\.h"/g, "").replace(/:\s*PBCodable\s*<\s*\w+\s*>/g, ": NSObject").replace(/#import "IMChatTranscriptDrawable\.h"/, "").replace(/#import "IMDynamicGradientReferenceView\.h"/, "").replace(/#import "IMFromSuperParserContext.h"/g, "").replace(/CALayer<\w+>/g, "CALayer");
}

function fixCNCancelationTokenInheritance(line) {
    return line.replace(/\s:\sCNCancelationToken/g, " : NSObject").replace(/CNCancelationToken\s\*/g, "id");
}

function fixCNObservable(line) {
    return line.replace(/\s:\sCNObservable\s?<?[\w\d]*>?$/g, " : NSObject").replace(/#import "CNScheduler\.h"/g, "");
}

/**
 * Applys a transformer function to the given line
 * @param {Function} transformer 
 * @param {string} text 
 */
function apply(transformer, text) {
    return text.split('\n').map(line => transformer(line)).join('\n');
}

/**
 * Applies a series of transformations linearly
 * @param {Array<(str: string) => string>} transforms 
 * @param {string} text 
 */
function applyTransforms(text, transforms) {
    return transforms.reduce((text, transform) => transform(text), text);
}

/**
 * Fixes a line of text using the coded transformations
 * @param {string} text 
 */
function applyAllFixes(text) {
    return applyTransforms(text, [
        fixArrowImports,
        fixNSImports,
        fixIgnoredLines,
        fixCDUnknownBlockType,
        fixCNCancelable,
        fixMistypedHash,
        fixNSObjectParameterization,
        fixIDParameterization,
        fixIDPointer,
        fixBrokenStruct,
        fixCDStruct,
        fixPBCodable,
        fixCNCancelationTokenInheritance,
        fixCNObservable,
	fixFakeShit,
	fixFailParse
    ]);
}

const dir = process.argv[2];

console.log(`Fixing up ${dir}`);

const NAME_BLACKLIST = ["CDStructures.h", /NS\w+.h/g, /CLS.*\.h/g];
const exclude = (str) => NAME_BLACKLIST.some(name => isRegExp(name) ? (name.exec(str)) : (str === name));
const files = fs.readdirSync(dir);

files
    .filter(name => exclude(name))
    .map(name => path.join(dir, name))
    .forEach(path => fs.unlinkSync(path));

files
    .filter(name => !exclude(name))
    .map(name => path.join(dir, name))
    .map(path => ({ path, text: fs.readFileSync(path).toString() }))
    .map(({ path, text }) => ({ path, text: apply(fixArrowImports, text) }))
    .map(({ path, text }) => ({ path, text: apply(fixNSImports, text) }))
    .map(({ path, text }) => ({ path, text: apply(fixIgnoredLines, text) }))
    .map(({ path, text }) => ({ path, text: apply(fixCDUnknownBlockType, text) }))
    .map(({ path, text }) => ({ path, text: applyAllFixes(text) }))
    .forEach(({ path, text }) => fs.writeFileSync(path, text));

console.log(`Fixed imports in ${files.length} files.`);
