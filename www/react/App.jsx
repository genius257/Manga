//import Nav from "./Nav";
import React from "react";
import {
  HashRouter as Router,
  Switch,
  Route,
  Link
} from "react-router-dom";
import ContextMenu from "./components/contextMenu.tsx";
import MaterialIcon from "./components/MaterialIcon";
import Search from "./components/Search.tsx";
import ToastContainer from "./components/ToastContainer.tsx";
import Api from "./pages/Api";
import Dashboard from "./pages/Dashboard";
import History from "./pages/History";
import Manga from "./pages/Manga";
import Chapter from "./pages/Manga/Chapter";
import Page from "./pages/Manga/Chapter/Page";
import SearchPage from "./pages/Search";
import Settings from "./pages/Settings";

export default class App extends React.Component {
    render() {
        //return <Nav />;
        //return <div>test</div>;
        return <Router>
            <>
                <nav>
                    <Link to="/" style={{borderBottom: "1px solid rgba(255, 255, 255, 0.1)"}} title="Home">
                        <MaterialIcon icon="home"/>
                    </Link>
                    <Link to="/api/" title="API's">
                        <MaterialIcon icon="api"/>
                    </Link>
                    <Link to="/settings/" title="Settings">
                        <MaterialIcon icon="settings"/>
                    </Link>
                </nav>
                <header>
                    <Link to="/"><figure style={{marginLeft: 0, marginRight: 0}}><img src="images/logo.png" /></figure></Link>
                    <label className="search">
                        <Search />
                    </label>
                    <div style={{display: "flex", flexDirection: "row", gap: "25px"}}>
                        <Link to="/history/" title="History">
                            <MaterialIcon icon="watch_later" style={{fontSize: "24px", color: "#D5D5D7"}}/>
                        </Link>
                        <Link to="/notifications/" title="Notifications">
                            <MaterialIcon icon="notifications" style={{fontSize: "24px", color: "#D5D5D7"}}/>
                        </Link>
                        <div className="hero"></div>
                    </div>
                </header>
                <main>
                    <Switch>
                        <Route path="/api/" component={Api}/>
                        <Route path="/history/" component={History}/>
                        <Route exact path="/manga/:mangaId/" component={Manga}/>
                        <Route exact path="/manga/:mangaId/chapter/:chapterId/" component={Chapter}/>
                        <Route exact path="/manga/:mangaId/chapter/:chapterId/page/:pageId/" component={Page}/>
                        <Route path="/settings/" component={Settings} />
                        <Route path="/search/" component={SearchPage} />
                        <Route exact path="/" component={Dashboard} />
                        <Route><i>404 Page not found.</i></Route>
                    </Switch>
                </main>
                <footer><ToastContainer/><ContextMenu/></footer>
            </>
        </Router>;
    }
}
