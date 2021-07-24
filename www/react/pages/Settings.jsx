import React from "react";
import ToastContainer from "../components/ToastContainer";

export default class Settings extends React.Component {
    render() {
        ToastContainer.add("#"+ToastContainer.getAutoIncrement());
        return "NOTHING HERE YET.";
    }
}
