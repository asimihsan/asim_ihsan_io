const path = require('path');
const fs = require('fs');

const currentScriptDir = path.dirname(
    require.main.filename || process.mainModule.filename
);

// root dir is two dirs up
const rootDir = path.join(currentScriptDir, '..', '..');

// build dir is root then hugo/build
const buildDir = path.join(rootDir, 'hugo', 'build');

// walk and find all directories and subdirectorie that have an index.html file.
const walk = (base, dir) => {
    let results = [];
    const contents = fs.readdirSync(dir);
    for (entry in contents) {
        const file = path.join(dir, contents[entry]);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(base, file));
        } else {
            if (file.endsWith('index.html')) {
                // strip prefix of the base
                let subdir = file.replace(base, '');

                // strip suffix of index.html
                subdir = subdir.replace('index.html', '');

                results.push(subdir);
            }
        }
    }
    return results;
};

const files = walk(buildDir, buildDir);
const base_url = 'https://asim.ihsan.io';
const urls = files.map(file => {
    return base_url + file;
});

const Crittr = require('crittr');

Crittr({
    urls: urls,
    device: {
        width: 1920,
        height: 1080,
    },
})
    .then(({ critical, rest }) => {
        console.log(critical);
    })
    .catch(err => {
        console.error(err);
    });
