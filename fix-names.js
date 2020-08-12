const fs = require("fs");
const path = require("path");

const dir = process.argv[2];

/**
 * 
 * @param {string} name 
 */
function fixName(name) {
    if (name.endsWith('-Protocol.h')) return `${name.substring(0, name.length - '-Protocol.h'.length)}.h`;
    return null;
}

const items = fs.readdirSync(dir)
                .map(oldName => ({ oldName, newName: fixName(oldName) }))
                .filter(({ oldName, newName }) => newName !== null)

            items
                .map(({ oldName, newName }) => ({ oldPath: path.resolve(dir, oldName), newPath: path.resolve(dir, newName) }))
                .forEach(({ oldPath, newPath }) => fs.renameSync(oldPath, newPath));

console.log(`Fixed names of ${items.length} items`);