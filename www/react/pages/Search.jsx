import React from "react";
import {
    HashRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import Poster from "../components/Poster";

export default class Search extends React.Component {
    state = {
        query: null,
        results: []
    };

    componentDidMount() {
        this.updateQuery();
    }

    componentDidUpdate(prevProps, prevState, snapshot) {
        if (this.props?.location?.search !== prevProps?.location?.search) {
            this.updateQuery();
        }
        if (this.state.query !== prevState.query) {
            fetch(`/api/search/?q=${this.state.query}`).then(response => response.json()).then(results => this.setState({results}));
        }
    }

    updateQuery() {
        const searchParams = new URLSearchParams(this.props?.location?.search ?? "");
        this.setState({query: searchParams.get('q')});
    }

    render() {
        //FIXME: we need to call API to get search and display output
        return <>{this.state.results.map(manga => <Link key={manga.id} to={`/manga/${manga.id}/`}><Poster title={manga.name} api={manga.api} image={`/data/${manga?.pathId ?? ""}/${manga?.poster ?? ""}`} /></Link>)}</>;
    }
}
