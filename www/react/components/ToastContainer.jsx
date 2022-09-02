import React from "react";
//import "./ToastContainer.css";

export default class ToastContainer extends React.Component {
    static _items = []; //instances of active toasts
    static _instances = []; //instances of self.
    static _onClickHandle;
    static _AUTO_INCREMENT = 0;

    //FIXME: setting _max > 1 results in bad handling when removing context menu
    static _max = 5; //the max ammount of context menus allowed at the same time.

    static getAutoIncrement() {
        return this._AUTO_INCREMENT;
    }

    static setMax(max) {
        this._max = max;
    }
    
    static add(data) {
        while (this._items.length >= this._max && this._items.length > 0) {
          this._items.shift(); //TODO: maybe use slice instead, to avoid the loop.
        }
        let key = this._AUTO_INCREMENT;
        if (data) {
            let key = this._AUTO_INCREMENT++;
            this._items.push(
                <Toast key={key}>
                    {data}
                </Toast>
            );
        }
        this.refreshInstances();
        return key;
    }
    
    static remove(key) {
        let index = this._items.findIndex(i => i.key === key);
        if (index !== -1) this._items.splice(index, 1);
        this.refreshInstances();
    }
    
    static refreshInstances() {
        this._instances.forEach(i => i.forceUpdate());
    }
    
    static _onClick(e) {
        if (this._items.length === 0 || this._items.every(i => i === null)) return;
        if (
          this._instances.every(i => !ReactDOM.findDOMNode(i).contains(e.target))
        ) {
          //e.stopPropagation();
          //e.stopImmediatePropagation();
          e.preventDefault();
          this.add(null);
          const preventClick = function(e) {
            e.preventDefault();
            // window.removeEventListener("click", preventClick, true); //FIXME: add setTimeout to check mouse button status (if mousedown in browser and mouse up outside of browser and remove event listner if true)
          };
          // window.addEventListener("click", preventClick, true);
        } else {
          if (
            e.target.className === "toast" ||
            e.target.hasAttribute("disabled")
          ) {
            return;
          }
          const removeContextMenu = e => {
            this.add(null);
            // window.removeEventListener("click", removeContextMenu, false); //FIXME: add setTimeout to check mouse button status (if mousedown in browser and mouse up outside of browser and remove event listner if true)
          };
          // window.addEventListener("click", removeContextMenu, false);
        }
        //console.log(this._items, ReactDOM.findDOMNode(this._instances[0]));
        //console.log(this._items.every(i => ReactDOM.findDOMNode(i).contains));
        //console.log(this._items.every(i => i.contains(e.target)));
    }
    
    componentDidMount() {
        this.constructor._instances.push(this);
        if (this.constructor._instances.length === 1 && !this._onClickHandle) {
          this.constructor._onClickHandle = e => this.constructor._onClick(e);
          /*
          window.addEventListener(
            "mousedown",
            this.constructor._onClickHandle,
            true
          ); //https://github.com/d3/d3-drag/issues/9
          */
        }
    }
    
    componentWillUnmount() {
        let index = this.constructor._instances.indexOf(this);
        this.constructor._instances.splice(index, 1);
        if (this.constructor._instances.length === 0 && this._onClickHandle) {
          //window.removeEventListener("mousedown", this._onClickHandle, true);
          this.constructor._onClickHandle = null;
          this.constructor._max = 1;
          this.constructor.add(null);
        }
    }
    
    render() {
        return <div style={{position: "absolute", right: "30px", bottom: "10px", display: "flex", flexDirection: "column", gap: "5px", ...this.props.style}}>{this.constructor._items}</div>;
    }
}

export class Toast extends React.Component {
    state = {
      show: false
    };
  
    /*constructor(props) {
      super(props);
  
      //Manager.
    }*/
  
render() {
    return (
        <div
          className="toast"
          /*style={{
            position: "absolute",
            left: this.props.x,
            top: this.props.y
          }}*/
        >
          {this.props.children}
        </div>
      );
    }
}
/*
export class ContextMenuItem extends React.Component {
    render() {
        return (
            <div className="contextMenuItem" {...this.props}>
            {this.props.children}
            </div>
        );
    }
}
*/
