(function (global, factory) {
    if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
        // CommonJS
        factory(exports);
    } else {
        // Browser globals
        factory(global);
    }
})(this, function (global) {
    function isArray(it) {
        return Object.prototype.toString.call(it) === '[object Array]';
    }

    var definitions = {};
    var aliases = {
        "react": React,
        "react-dom": ReactDOM,
        "react-router-dom": ReactRouterDOM,
    };

    global.define = function (name, deps, callback) {
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

        if (isArray(deps) && deps.length) {
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

                var url = name;
                try {
                    new URL(url);
                } catch (e) {
                    var location = window.location;
                    url = new URL(url, `${location.protocol}//${location.hostname}${location.pathname}`).href;
                }
                var url = new URL(dependency, url).href;//requires us to know the url we base this call on.
                const fileName = url.split('/').pop();
                const ext = fileName.includes('.') ? url.split('.').pop() : '';
                if (ext === '' && !url.endsWith('/')) {
                    switch (name.split('/').pop().split('.').pop()) {
                        case 'tsx':
                        case 'ts':
                            url = url + '.ts';
                            break;
                        default:
                            url = url + '.jsx';
                            break;
                    }
                }

                if (definitions[url]) {
                    return new Promise(resolve => {
                        resolve(definitions[url]);
                    });
                }

                let promise = fetch(url, {
                    cache: 'force-cache'
                })
                    .then(response => response.text());

                if (ext === "css") {
                    if (definitions[url] === undefined) {
                        definitions[url] = true;
                        const link = document.createElement("link");
                        link.href = url;
                        link.rel = "stylesheet";
                        document.head.appendChild(link);
                    }
                    promise
                        .then(css => console.log(css));
                } else {
                    promise = promise
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
                }
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

    global.define.amd = true;
});
