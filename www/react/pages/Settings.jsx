import React from "react";
import ToastContainer from "../components/ToastContainer";

export default class Settings extends React.Component {
    render() {
        ToastContainer.add("#"+ToastContainer.getAutoIncrement(), ['success', 'info', 'warning', 'error'][ToastContainer.getAutoIncrement() % 4]);
        return "NOTHING HERE YET.";
    }
}
