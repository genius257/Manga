import { withRouter, RouteComponentProps } from "react-router-dom";
import React from "react";
import { debounce } from "../helpers";

export type SearchProps = RouteComponentProps & {
    //
};

export type SearchState = {
    searchString: string
};

class Search extends React.Component<SearchProps, SearchState> {
    state:Readonly<SearchState> = {
        searchString: "",
        //value: "",
    };

    onChangeDebounced: () => void;

    constructor(props: Readonly<SearchProps> | SearchProps) {
        super(props);
        this.onChangeDebounced = debounce(this.pushHistoryState, 500); //used to be 250
    }

    componentDidMount():void {
        const searchParams = new URLSearchParams(this.props.location.search);
        this.setState({
            searchString: searchParams.get('q') ?? ''
        });
    }

    componentDidUpdate(prevProps: Readonly<SearchProps>, prevState: Readonly<SearchState>, snapshot?: any):void {
        if (this.props.location.search !== prevProps.location.search) {
            const searchParams = new URLSearchParams(this.props.location.search);
            this.setState({ searchString: searchParams.get('q') ?? '' });
        }
    }
    
    searchChange = (event: React.ChangeEvent<HTMLInputElement>):void => {
        this.setState({ searchString: event.target.value });
        this.onChangeDebounced();
    };
    
    pushHistoryState = () => {
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
