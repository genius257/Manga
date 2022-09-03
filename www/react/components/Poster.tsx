import React from "react";

export type PosterProps = {
    marked?: boolean,
    title: string,
    image: string,
    api: string,
};

export default class Poster extends React.Component<PosterProps> {
    render() {
        const imageClassNames = ["image", this.props?.marked ? "marked" : null].filter(v => v).join(" ");
        return <div className="card">
            <div className={imageClassNames} style={{backgroundImage: `url('${this.props.image}')`}}></div>
            <div className="title">{this.props.title}</div>
            <div className="title secondary">{this.props.api}</div>
        </div>;
    }
}
