import React from "react";

export default class Poster extends React.Component {
    render() {
        return <div className="card">
            <div className="image" style={{backgroundImage: `url('${this.props.image}')`}}></div>
            <div className="title">{this.props.title}</div>
            <div className="title secondary">{this.props.api}</div>
        </div>;
    }
}
