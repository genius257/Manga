import { withRouter } from "react-router-dom";
import React from "react";
import { debounce } from "../helpers";

class Search extends React.Component {
    state = {
        searchString: "",
        value: ""
    };

    constructor(props) {
        super(props);
        this.onChangeDebounced = debounce(this.pushHistoryState.bind(this), 500); //used to be 250
        this.searchChange = this.searchChange.bind(this);
    }

    componentDidMount() {
        const searchParams = new URLSearchParams(this.props?.location?.search ?? "");
        this.setState({
            searchString: searchParams.get('q') ?? ''
        });
    }
    
    componentDidUpdate(prevProps, prevState, snapshot) {
        if (this.props.location.search !== prevProps.location.search) {
            const searchParams = new URLSearchParams(this.props?.location?.search ?? "");
            this.setState({ searchString: searchParams.get('q') ?? '' });
        }
    }
    
    searchChange = function (e) {
        this.setState({ searchString: e.target.value });
        this.onChangeDebounced();
    };
    
    pushHistoryState = function () {
        if (this.state.searchString) {
            this.props.history.push(`/search/?q=${this.state.searchString}`);
        } else {
            this.props.history.push("/"); //FIXME: we could save the history path from before the search state was pushed and restore it here, with / as a fallback
        }
    };
    
    render() {
        return <input
            type="text"
            placeholder="Search..."
            onChange={this.searchChange}
            value={this.state.searchString}
        />;
    }
}

export default withRouter(Search);
