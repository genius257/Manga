import React from "react";
import {
    HashRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import Poster from "../components/Poster.tsx";
import ToastContainer from "../components/ToastContainer.tsx";

export default class Dashboard extends React.Component {
    state = {
        mangas: [],
        marginLeft: 0,
    };

    constructor(props) {
        super(props);
        this.hubSrollButtonMove = this.hubSrollButtonMove.bind(this);
    }

    componentDidMount() {
        fetch('/api/mangas/').then(response => response.json()).then(mangas => this.setState({mangas})).catch(reason => ToastContainer.add(reason.toString(), 'error'));
    }

    hubSrollButtonMove(e) {
        //TODO: we need to calculate if any items is out of bound inn the hubScroll.

        const forward = e.currentTarget.classList.contains('forward');
        if (forward || this.state.marginLeft < 0) {
            this.setState({
                marginLeft: this.state.marginLeft += forward ? -100 : 100
            })
        }
    }

    render() {
        return <>
            <div className="hub">
                <div className="hubHeader">
                    <span className="hubTitle">Continue Reading</span>
                    <div className="hubAction">
                        <button className="hubSrollButton" onClick={this.hubSrollButtonMove}>
                            <span className="material-icons">
                                chevron_left
                            </span>
                        </button>
                        <button className="hubSrollButton forward" onClick={this.hubSrollButtonMove}>
                            <span className="material-icons">
                                chevron_right
                            </span>
                        </button>
                    </div>
                </div>
                <div style={{display: "flex", flexDirection: "row", gap: "15px", transition: "margin 0.5s ease 0s", marginLeft: `${this.state.marginLeft}%`}}>
                    {this.state.mangas.map((manga, index) => <Link to={`/manga/${manga.id}/`} key={manga?.id ?? index}><Poster image={`/data/${manga.pathId}/${manga.poster}`} title={manga.name} api={manga.api}></Poster></Link>)}
                </div>
            </div>
        </>;
    }
}
