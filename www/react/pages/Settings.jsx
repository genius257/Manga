import React from "react";
import ToastContainer from "../components/ToastContainer.tsx";
import Poster from "../components/Poster.tsx"; //BUG: A bug in the AMD dependency resolver, breaks ToastContainer import, without this line. WIP

export default class Settings extends React.Component {
    render() {
        ToastContainer.add("#"+ToastContainer.getAutoIncrement(), ['success', 'info', 'warning', 'error'][ToastContainer.getAutoIncrement() % 4]);
        return "NOTHING HERE YET.";
    }
}
