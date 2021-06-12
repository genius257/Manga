document.addEventListener("DOMContentLoaded", (event) => {
    fetch('/tmpl/main.tmpl').then(response => {
        return response.text()
    }).then(text => {
        fetch('/tmpl/poster.tmpl').then(response => response.text()).then(poster => {
            tmplCache['poster'] = tmpl(poster);
            fetch('/api/manga/').then(response => response.json()).then(mangas => {
                document.body.innerHTML = tmpl(text, {mangas: mangas});
                document.getElementById('update').addEventListener('click', e => fetch('/api/mangaSvc/?start'));
            })
        });
    });
    //document.body.appendChild(document.createTextNode("test"));
    //document.body.innerHTML = tmpl("test", {})
});
