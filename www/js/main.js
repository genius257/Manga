function isArray(it) {
    return Object.prototype.toString.call(it) === '[object Array]';
}
var definitions = {};
var aliases = {
    "react": React,
    "react-dom": ReactDOM,
    "react-router-dom": ReactRouterDOM,
};
function define(name, deps, callback) {
    //WARNING: if name is not present, our module path resolve will fail HARD!

    //Allow for anonymous modules
    if (typeof name !== 'string') {
        //Adjust args appropriately
        callback = deps;
        deps = name;
        name = null;
    }

    //This module may not have dependencies
    if (!isArray(deps)) {
        callback = deps;
        deps = null;
    }

    if (isArray(deps)&&deps.length) {
        return Promise.all(deps.map(dependency => {
            if (dependency == 'exports') {
                return new Promise(resolve => {
                    definitions[name] = {};
                    //callback(definitions[name]);
                    resolve(definitions[name]);
                });
            }

            if (aliases.hasOwnProperty(dependency)) {
                return new Promise(resolve => {
                    resolve(aliases[dependency]);
                });
            }

            //FIXME: we need to check if the required resource is chached in the "definitions" object and return it if it is, to save on resources.

            var url = name;
            try {
                new URL(url);
            } catch (e) {
                url = new URL(url, window.location.href).href; //FIXME: we should not use window.location.href, but only protocol, hostname and path. Query string and get parameters should be ignored.
            }
            var url = new URL(dependency, url).href;//requires us to know the url we base this call on.
            if (definitions[url]) {
                return new Promise(resolve => {
                    resolve(definitions[dependency]);
                });
            }
            const fileName = url.split('/').pop();
            const ext = fileName.includes('.') ? url.split('.') : '';
            if (!ext && !url.endsWith('/')) {
                url = url + '.jsx';
            }

            const promise = fetch(url, {
                cache: 'force-cache'
            })
                .then(response => response.text())
                .then(body => Babel.transform(body, {
                        filename: fileName,
                        presets: [
                            'react',
                            'typescript'
                        ],
                        plugins: [
                            'proposal-dynamic-import',
                            'transform-modules-amd'
                        ],
                        sourceMaps: true,
                        moduleId: url
                    }).code
                ).then(code => {
                    //definition.apply(null, [code]);
                    return eval(code).then(result => {
                        definitions[url] = result;
                        //callback(definitions[name]);
                        return definitions[url];
                    });
                    //return code;
                });
            definitions[url] = promise;
            return promise;
        })).then(dependencies => {
            callback(...dependencies);
            return definitions[name];
        });

        if (deps[0] == 'exports') {
            return new Promise(resolve => {
                definitions[name] = {};
                callback(definitions[name]);
                resolve(definitions[name]);
            });
        }

        var url = name;
        try {
            new URL(url);
        } catch (e) {
            url = new URL(url, window.location.href).href;
        }
        var url = new URL(deps[0], url).href;//requires us to know the url we base this call on.
        const fileName = url.split('/').pop();
        const ext = fileName.includes('.') ? url.split('.') : '';
        if (!ext && !url.endsWith('/')) {
            url = url + '.jsx';
        }
        console.log(url);
        return fetch(url)
            .then(response => response.text())
            .then(body => Babel.transform(body, {
                    presets: [
                        'react',
                    ],
                    plugins: [
                        'proposal-dynamic-import',
                        'transform-modules-amd'
                    ],
                    sourceMaps: true,
                    moduleId: url
                }).code
            ).then(code => {
                //console.log(code);
                //definition.apply(null, [code]);
                return eval(code).then(result => {
                    //console.log(code);
                    console.log(result);
                    definitions[name] = result;
                    callback(definitions[name]);
                    return definitions[name];
                });
                //return code;
            });
    }
    console.log("here", name);
    return new Promise(resolve => resolve({}));
}
