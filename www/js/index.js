document.addEventListener("DOMContentLoaded", (event) => {
    fetch('/tmpl/dashboard.tmpl').then(response => {
        return response.text()
    }).then(text => {
        fetch('/tmpl/poster.tmpl').then(response => response.text()).then(poster => {
            tmplCache['poster'] = tmpl(poster);
            fetch('/api/manga/').then(response => response.json()).then(mangas => {
                document.body.innerHTML = tmpl(text, {mangas: mangas});
                document.getElementById('update').addEventListener('click', e => fetch('/api/mangaSvc/?start'));
                Array.prototype.forEach.call(document.getElementsByClassName('hubSrollButton'), button => {
                    button.addEventListener('click', e => {
                        const target = button.parentElement.parentElement.nextElementSibling;
                        const targetRect = target.getBoundingClientRect();
                        const marginLeft = Number.parseInt(target.style.marginLeft.slice(0, -2)||0);
                        if (marginLeft >= 0 && !button.classList.contains('forward') || button.classList.contains('forward') && (targetRect.right - Math.abs(targetRect.left)) <= Math.abs(marginLeft)) {
                            return
                        }
                        const margin = targetRect.right;
                        target.style.marginLeft = (button.classList.contains('forward') ? marginLeft - margin : marginLeft + margin) + "px";
                    });
                });
            });
        });
    });
});
