const fs = require("fs");
const path = require("path");

const dir = process.argv[2];
const framework = process.argv[3];

const umbrellaName = `${framework}.h`
const umbrellaPath = path.resolve(dir, umbrellaName);

const umbrella = fs.readdirSync(dir)
                   .filter(file => !file.startsWith('.'))
                   .map(file => `#import <${framework}/${file}>`)
                   .join('\n')

fs.writeFileSync(umbrellaPath, umbrella);

console.log(`Wrote umbrella to ${umbrellaPath}`);