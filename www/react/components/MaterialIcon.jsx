import React from "react";

export default class MaterialIcon extends React.Component {
    render() {
        const className = ["material-icons", this.props.className].filter(v => v).join(' ');
        return <span {...this.props} className={className}>{this.props.icon}</span>
    }
}
