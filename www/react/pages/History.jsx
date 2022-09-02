import MaterialIcon from "../components/MaterialIcon";
import React from "react";
import ToastContainer from "../components/ToastContainer.tsx";

export default class History extends React.Component {
    state = {
        after: 0,
        history: []
    };

    componentDidMount() {
        this.loadHistory();
    }

    componentDidUpdate(prevProps, prevState, snapshot) {
        if(prevState.after !== this.state.after) {
            //console.log(prevState.offset, this.state.offset);
            this.loadHistory();
        }
    }

    loadHistory() {
        fetch(`/api/history/?order=0${(this.state.after > 0 ? "&before="+this.state.after : "")}`).then(response => response.json()).then(history => Promise.all(history.map(history => 
            fetch(`/api/page/:${history.page_id}/`).then(response => response.json()).then(page =>
                fetch(`/api/chapter/:${page[0].chapter_id}/`).then(response => response.json()).then(chapter => 
                    fetch(`/api/mangas/:${chapter[0].manga_id}/`).then(response => response.json()).then(manga => {return {page: page[0], chapter: chapter[0], manga: manga[0], history: history};})
                )
            )
        ))).then(history => this.setState({history})).catch(reason => ToastContainer.add(reason.toString(), 'error'));
    }

    render() {
        //console.log(this.state.history);
        return <div style={{padding: "50px 0"}}>
            <table style={{margin: "0 auto"}}>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Chapter</th>
                        <th>Page</th>
                        <th>Date</th>
                    </tr>
                </thead>
                <tbody>
                    {this.state.history.map(history => {return <tr key={history.history.id}><td>{history.manga.name}</td><td>{history.chapter.name}</td><td>{history.page.name}</td><td>{(new Date((history.history.updated_at || history.history.created_at)*1000)).toLocaleString()}</td></tr>})}
                    <tr style={{cursor: "pointer"}} onClick={e => this.setState({after: (this.state.history[this.state.history.length-1].history.updated_at || this.state.history[this.state.history.length-1].history.created_at)})}>
                        <th colSpan="4">
                            <MaterialIcon icon="expand_more" />
                        </th>
                    </tr>
                </tbody>
            </table>
        </div>;
    }
}