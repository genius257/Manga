import { withRouter, RouteComponentProps } from "react-router-dom";
import React from "react";
import { debounce } from "../helpers";
import { Location } from "types/history/index";

export type SearchProps = RouteComponentProps & {
    //
};

export type SearchState = {
    searchString: string,
    /** The address of the page initiating the search */
    referer: Location|null,
};

class Search extends React.Component<SearchProps, SearchState> {
    state:Readonly<SearchState> = {
        searchString: "",
        referer: null,
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
            if (this.state.referer === null) {
                this.setState({
                    referer: this.props.history.location
                });
            }
            this.props.history.push(`/search/?q=${this.state.searchString}`);
        } else {
            if (this.state.referer === null) {
                this.props.history.push("/");
                return;
            }

            const referer = this.state.referer;
            this.setState({
                referer: null,
            });
            this.props.history.push(referer);
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
