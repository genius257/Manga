import React from "react";
import {
    HashRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import Poster from "../components/Poster";

export default class Manga extends React.Component {
    state = {
        manga: {},
        chapters: []
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
        fetch(`/api/mangas/:${mangaId}/`).then(response => response.json()).then(mangas => {
            fetch(`/api/mangas/:${mangaId}/chapters/?order=0`).then(response => response.json()).then(chapters => this.setState({manga: mangas[0], chapters: chapters}));
        });
    }

    render() {
        const manga = this.state.manga;
        const imagePath = `/data/${manga?.pathId ?? ""}/${manga?.poster ?? ""}`;
        const title = manga?.name ?? "";
        const api = manga?.api ?? "";
        return <>
            <Poster image={imagePath} title={title} api={api} />
            <table>
                <thead>
                    <tr>
                        <th>name</th><th>date added</th><th>watched</th>
                    </tr>
                </thead>
                <tbody>
                    {this.state.chapters.map(chapter =><tr key={chapter.id}><td><Link to={`/manga/${chapter.manga_id}/chapter/${chapter.id}/`}>{chapter?.name}</Link></td><td>{chapter?.date_added}</td><td>{chapter?.pages_watched} of {chapter?.pages}</td></tr>)}
                </tbody>
            </table>
        </>
    }
}
