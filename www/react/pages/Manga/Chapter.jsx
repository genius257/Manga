import React from "react";
import {
    HashRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import Poster from "../../components/Poster";
import ToastContainer from "../../components/ToastContainer";

export default class Chapter extends React.Component {
    state = {
        manga: {},
        chapter: {},
        pages: []
    }

    componentDidMount() {
        this.loadManga();
    }

    componentDidUpdate(prevProps, prevState, snapshot) {
        if(prevProps.match.params.mangaId !== this.props.match.params.mangaId) {
            this.loadManga();
        }
    }

    loadManga() {
        const mangaId = this.props.match.params.mangaId;
        const chapterId = this.props.match.params.chapterId;
        fetch(`/api/mangas/:${mangaId}/`).then(response => response.json()).then(mangas => {
            fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/`).then(response => response.json()).then(chapters => {
                //fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/pages/`).then(response => response.json()).then(pages => this.setState({manga: mangas[0], chapter: chapters[0], pages: pages}));
                this.setState({manga: mangas[0], chapter: chapters[0]});
                this.loadPages(mangaId, chapterId);
            });
        }).catch(reason => ToastContainer.add(reason.toString(), 'error'));;
    }

    loadPages(mangaId, chapterId, options = {}) {
        options.order = options?.order ?? 1;
        options.limit = options?.limit ?? 100;
        const query = Object.keys(options).map(option => `${option}=${encodeURIComponent(options[option])}`).join('&');
        return fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/pages/?${query}`).then(response => response.json()).then(pages => {
            if (!Array.isArray(pages) || pages.length === 0) {
                return [];
            }
            const _pages = this.state.pages.concat(pages);
            this.setState({pages: _pages}, () => {
                if (pages.length === options.limit) {
                    this.loadPages(mangaId, {
                        offset: (options?.offset ?? 0) + options.limit
                    });
                }
            });
            return pages;
        });
    }

    render() {
        const manga = this.state.manga;
        const imagePath = `/data/${manga?.pathId ?? ""}/${manga?.poster ?? ""}`;
        const title = manga?.name ?? "";
        const api = manga?.api ?? "";
        return <>
            <Link to={`/manga/${this.props.match.params.mangaId}/`}><Poster image={imagePath} title={title} api={api} /></Link>
            <div style={{display: "flex", flexDirection: "row", flexWrap: "wrap", gap: "10px"}}>
                {this.state.pages.map(page =><Link to={`/manga/${this.props.match.params.mangaId}/chapter/${page.chapter_id}/page/${page.id}/`} key={page.id}><Poster image={`/data/${this.state.manga.pathId}/${this.state.chapter.pathId}/${page.pathId}`} /></Link>)}
            </div>
        </>
    }
}
