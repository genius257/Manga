

// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensedvar PD = PD || {};
const tmplCache = {};
function tmpl(str, data) {
    // Figure out if we're getting a template, or if we need to
    // load the template - and be sure to cache the result.
    var fn = !/\W/.test(str) ?
            tmplCache[str] = // set cached template to...
            tmplCache[str] || // existing cached template
            //PD.templates[str] || // existing compiled template
            tmpl(document.getElementById(str).innerHTML || " ") // compile new template
            
            : // if it's a full template string, not an ID             // Generate a reusable function that will serve as a template

            // generator (and which will be cached).
            new Function("obj",
                "var p=[],print=function(){p.push.apply(p,arguments);};" +                // Introduce the data as local variables using with(){}
                "with(obj){p.push('" +                // Convert the template into pure JavaScript
                str.replace(/[\r\t\n]/g, " ")
                    .replace(/'(?=[^%]*%>)/g,"\t")
                    .split("'").join("\\'")
                    .split("\t").join("'")
                    .replace(/<%=(.+?)%>/g, "',$1,'")
                    .split("<%").join("');")
                    .split("%>").join("p.push('")
                    + "');}return p.join('');");
    // Provide some basic currying to the user
    return data ? fn(data) : fn;
}
