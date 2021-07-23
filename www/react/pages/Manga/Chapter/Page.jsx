import React from "react";
import {
    HashRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import MaterialIcon from "../../../components/MaterialIcon";
import Poster from "../../../components/Poster";

export default class Page extends React.Component {
    state = {
        manga: {},
        chapter: {},
        page: {},
        first: {},
        previous: {},
        next: {},
        last: {}
    }

    constructor(props) {
        super(props);
        this.onKeydown = this.onKeydown.bind(this);
    }

    componentDidMount() {
        this.loadPage();
        document.addEventListener("keydown", this.onKeydown, false);
    }

    componentWillUnmount() {
        document.removeEventListener("keydown", this.onKeydown, false);
    }

    componentDidUpdate(prevProps, prevState, snapshot) {
        if(prevProps.match.params.pageId !== this.props.match.params.pageId) {
            this.loadPage();
        }
    }

    loadPage() {
        const mangaId = this.props.match.params.mangaId;
        const chapterId = this.props.match.params.chapterId;
        const pageId = this.props.match.params.pageId;
        fetch(`/api/mangas/:${mangaId}/`).then(response => response.json()).then(mangas => {
            fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/`).then(response => response.json()).then(chapters => {
                fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/pages/:${pageId}/`).then(response => response.json()).then(pages => {
                    document.querySelector("main").scrollTo(0, 0);
                    this.setState({manga: mangas[0], chapter: chapters[0], page: pages[0]});
                    const page = pages[0];
                    const pageIndex = page.index;
                    fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/pages/?limit=3&offset=${pageIndex - 2}`).then(response => response.json()).then(pages => {
                        const previous = pageIndex > 1 ? pages[0] : {};
                        const next = pages[2];
                        this.setState({
                            previous: previous,
                            next: next
                        });

                        if (next?.id === page?.index || next?.id === undefined) {
                            fetch(`/api/mangas/:${mangaId}/chapters/?limit=1&offset=${chapters[0].index}`).then(response => response.json()).then(chapters => {
                                console.log(chapters);
                                fetch(`/api/mangas/:${mangaId}/chapters/:${chapters[0].id}/pages/?limit=1`).then(response => response.json()).then(pages => this.setState({next: pages[0] || {}}))
                            });
                        }

                        if (previous.id === page.index || previous?.id === undefined) {
                            fetch(`/api/mangas/:${mangaId}/chapters/?limit=1&offset=${chapters[0].index - 2}`).then(response => response.json()).then(chapters => {
                                fetch(`/api/mangas/:${mangaId}/chapters/:${chapters[0].id}/pages/?limit=1&order=0`).then(response => response.json()).then(pages => this.setState({previous: pages[0]}))
                            });
                        }
                    });
                    fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/pages/?limit=1&order=1`).then(response => response.json()).then(pages => this.setState({first: pages[0] ?? {}}));
                    fetch(`/api/mangas/:${mangaId}/chapters/:${chapterId}/pages/?limit=1&order=0`).then(response => response.json()).then(pages => this.setState({last: pages[0] ?? {}}));
                });
            });
        });
    }

    onKeydown(event) {
        switch(event.key) {
            case 'ArrowLeft':
                this.previousPage();
                break;
            case 'ArrowRight':
                this.nextPage();
                break;
        }
    }

    previousPage() {
        const mangaId = this.props.match.params.mangaId;
        const chapterId = this.props.match.params.chapterId;
        const pageId = this.props.match.params.pageId;

        this.props.history.push(`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.previous.id ?? pageId}/`);
    }

    nextPage() {
        const mangaId = this.props.match.params.mangaId;
        const chapterId = this.props.match.params.chapterId;
        const pageId = this.props.match.params.pageId;

        this.props.history.push(`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.next.id ?? pageId}/`);
    }

    firstPage() {
        const mangaId = this.props.match.params.mangaId;
        const chapterId = this.props.match.params.chapterId;
        const pageId = this.props.match.params.pageId;

        this.props.history.push(`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.first.id}/`);
    }

    lastPage() {
        const mangaId = this.props.match.params.mangaId;
        const chapterId = this.props.match.params.chapterId;
        const pageId = this.props.match.params.pageId;

        this.props.history.push(`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.last.id}/`);
    }

    render() {
        const mangaId = this.props.match.params.mangaId;
        const chapterId = this.props.match.params.chapterId;
        const pageId = this.props.match.params.pageId;

        return <div style={{display: "flex", flexDirection: "column", alignItems: "center"}}>
            <div style={{display: "flex", flexDirection: "row", alignItems: "center"}}>
                <Link to={`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.first?.id}/`}><MaterialIcon icon="first_page"/></Link>
                <Link to={`/manga/${mangaId}/chapter/${this.state.previous?.chapter_id ?? chapterId}/page/${this.state.previous?.id ?? pageId}/`}><MaterialIcon icon="chevron_left"/></Link>
                {this.state.page?.index} / {this.state.last?.index}
                <Link to={`/manga/${mangaId}/chapter/${this.state.next?.chapter_id ?? chapterId}/page/${this.state.next?.id ?? pageId}/`}><MaterialIcon icon="chevron_right"/></Link>
                <Link to={`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.last?.id}/`}><MaterialIcon icon="last_page"/></Link>
            </div>
            <Link to={`/manga/${mangaId}/chapter/${this.state.next?.chapter_id ?? chapterId}/page/${this.state.next?.id ?? pageId}/`}><img src={`/data/${this.state.manga.pathId}/${this.state.chapter.pathId}/${this.state.page.pathId}`} /></Link>
            <div style={{display: "flex", flexDirection: "row", alignItems: "center"}}>
                <Link to={`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.first?.id}/`}><MaterialIcon icon="first_page"/></Link>
                <Link to={`/manga/${mangaId}/chapter/${this.state.previous?.chapter_id ?? chapterId}/page/${this.state.previous?.id ?? pageId}/`}><MaterialIcon icon="chevron_left"/></Link>
                {this.state.page?.index} / {this.state.last?.index}
                <Link to={`/manga/${mangaId}/chapter/${this.state.next?.chapter_id ?? chapterId}/page/${this.state.next?.id ?? pageId}/`}><MaterialIcon icon="chevron_right"/></Link>
                <Link to={`/manga/${mangaId}/chapter/${chapterId}/page/${this.state.last?.id}/`}><MaterialIcon icon="last_page"/></Link>
            </div>
            <div>
                <Link to={`/manga/${mangaId}/chapter/${chapterId}/`}><MaterialIcon icon="expand_more"/></Link>
            </div>
        </div>
    }
}
