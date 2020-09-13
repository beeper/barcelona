const fs = require("fs");
const path = require("path");

const SDK_PATH = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/PrivateFrameworks";

const name = process.argv[2];
const tbdSourcePath = path.resolve(SDK_PATH, `${name}.framework`, 'Versions/A', `${name}.tbd`);
const frameworkPath = path.resolve(__dirname, "Frameworks", `${name}.framework`);
const tbdTargetPath = path.resolve(frameworkPath, `${name}.tbd`);
const headersPath = path.resolve(frameworkPath, "Headers");
const modulesPath = path.resolve(frameworkPath, "Modules");
const moduleMapPath = path.resolve(modulesPath, "module.modulemap");

if (!fs.existsSync(frameworkPath)) {
    fs.mkdirSync(frameworkPath);
    fs.mkdirSync(headersPath);
    fs.mkdirSync(modulesPath);
}

fs.copyFileSync(tbdSourcePath, tbdTargetPath);
fs.writeFileSync(moduleMapPath, `framework module ${name} [extern_c] {
    umbrella header "${name}.h"
    export *
    module * { export * }
}
`);
