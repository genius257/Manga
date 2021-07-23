import React from "react";
import {
    HashRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import Poster from "../../components/Poster";

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
                fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/pages/`).then(response => response.json()).then(pages => this.setState({manga: mangas[0], chapter: chapters[0], pages: pages}));
            });
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
