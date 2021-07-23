export default class Api extends React.Component {
    render() {
        return <div className="hub" style={{width: "1000px", margin: "0 auto"}}>
            <div className="hubHeader">
                <span className="hubTitle">API's</span>
            </div>
            <div style={{display: "flex", flexDirection: "row", gap: "15px", flexWrap: "wrap"}}>
                <a href="/api/taadd/" target="_blank" rel="noopener noreferrer"><div className="card" style={{width:"145px", height: "145px"}}><div className="image" style={{height: "145px", backgroundImage: "url('/images/Taadd.png')", backgroundSize: "contain", backgroundPosition: "center"}}></div><div className="title">Taadd</div></div></a>
            </div>
        </div>;
    }
}
