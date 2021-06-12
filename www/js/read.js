window.addEventListener('DOMContentLoaded', e => {
    window.addEventListener('keyup', e => {
        switch (e.code) {
            case 'ArrowLeft':
                window.location.assign(document.getElementById('previous').parentElement.href);
                //window.location.assign(window.location.search)
                //window.location.search.replace(/(chapter=)[^&]+/, '$12')
                break;
            case 'ArrowRight':
                window.location.assign(document.getElementById('next').parentElement.href);
                break;
            default:
                break;
        }
    })
});
