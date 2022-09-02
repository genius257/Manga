import React from "react";
import {
    HashRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import ContextMenu, { ContextMenuItem } from "../components/contextMenu";
import Poster from "../components/Poster";
import ToastContainer from "../components/ToastContainer";

export default class Manga extends React.Component {
    state = {
        manga: {},
        chapters: []
    }

    constructor(props) {
        super(props);

        this.onContextMenu = this.onContextMenu.bind(this);
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
            this.setState({manga: mangas[0]});
            this.loadChapters(mangaId);
            //fetch(`/api/mangas/:${mangaId}/chapters/?order=0&limit=100`).then(response => response.json()).then(chapters => this.setState({manga: mangas[0], chapters: chapters}));
        }).catch(reason => ToastContainer.add(reason.toString(), 'error'));
    }

    async loadChapters(mangaId, options = {}) {
        options.order = options?.order ?? 0;
        options.limit = options?.limit ?? 100;
        const query = Object.keys(options).map(option => `${option}=${encodeURIComponent(options[option])}`).join('&');
        return fetch(`/api/mangas/:${mangaId}/chapters/?${query}`).then(response => response.json()).then(chapters => {
            if (!Array.isArray(chapters) || chapters.length === 0) {
                return [];
            }
            const _chapters = this.state.chapters.concat(chapters);
            this.setState({chapters: _chapters}, () => {
                if (chapters.length === options.limit) {
                    this.loadChapters(mangaId, {
                        offset: (options?.offset ?? 0) + options.limit
                    });
                }
            });
            return chapters;
        });
    }

    onContextMenu(e) {
        e.preventDefault();

        const clickX = e.clientX;
        const clickY = e.clientY;
        const screenW = window.innerWidth;
        const screenH = window.innerHeight;
        const rootW = e.currentTarget.offsetWidth;
        const rootH = e.currentTarget.offsetHeight;

        const right = screenW - clickX > rootW;
        const left = !right;
        const top = screenH - clickY > rootH;
        const bottom = !top;

        ContextMenu.add(
            <>
                <ContextMenuItem>Mark as watched</ContextMenuItem>
                <ContextMenuItem>Mark as un-watched</ContextMenuItem>
                <ContextMenuItem>Update</ContextMenuItem>
            </>,
            e.pageX,
            e.pageY
        );
    }

    render() {
        const manga = this.state.manga;
        const imagePath = `/data/${manga?.pathId ?? ""}/${manga?.poster ?? ""}`;
        const title = manga?.name ?? "";
        const api = manga?.api ?? "";
        //FIXME: source link currently will only work with taadd links! need to find source homepage from mange information.
        return <div style={{padding: "10px"}}>
            <Poster image={imagePath} title={title} api={api} />
            <a href={`https://taadd.com${manga.url}`} target="_blank" rel="noopener noreferrer">Source link</a>
            <table>
                <thead>
                    <tr>
                        <th>name</th><th>date added</th><th>watched</th>
                    </tr>
                </thead>
                <tbody>
                    {this.state.chapters.map(chapter =><tr key={chapter.id} onContextMenu={this.onContextMenu}><td><Link to={`/manga/${chapter.manga_id}/chapter/${chapter.id}/`}>{chapter?.name}</Link></td><td>{chapter?.date_added}</td><td>{chapter?.pages_watched} of {chapter?.pages}</td></tr>)}
                </tbody>
            </table>
        </div>
    }
}
