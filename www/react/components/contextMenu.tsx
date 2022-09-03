import React from "react";
import ReactDOM from "react-dom";
//import PropTypes from "prop-types";

/*const ContextMenu = React.createContext(null);
export default ContextMenu;*/

export default class ContextMenuManager extends React.Component {
  static _items: JSX.Element[] = [];
  static _instances: ContextMenuManager[] = []; //instances of self.
  static _onClickHandle: null|((event: MouseEvent) => void);
  static _AUTO_INCREMENT = 0;

  //FIXME: setting _max > 1 results in bad handling when removing context menu
  static _max: number = 1; //the max ammount of context menus allowed at the same time.

  static setMax(max: number) {
    this._max = max;
  }

  static add(data: any, x: number = 0, y: number = 0) {
    while (this._items.length >= this._max && this._items.length > 0) {
      this._items.shift(); //TODO: maybe use slice instead, to avoid the loop.
    }
    let key = this._AUTO_INCREMENT;
    if (data) {
      let key = this._AUTO_INCREMENT++;
      this._items.push(
        <ContextMenu x={x} y={y} key={key}>
          {data}
        </ContextMenu>
      );
    }
    this.refreshInstances();
    return key;
  }

  static remove(key: React.Key) {
    let index = this._items.findIndex(i => i.props.key === key);
    if (index !== -1) this._items.splice(index, 1);
  }

  static refreshInstances() {
    this._instances.forEach(i => i.forceUpdate());
  }

  static _onClick(event: MouseEvent) {
    if (this._items.length === 0 || this._items.every(i => i === null)) return;
    const target = event.target as Element|null;
    if (
      this._instances.every(i => !ReactDOM.findDOMNode(i)?.contains(target))
    ) {
      //e.stopPropagation();
      //e.stopImmediatePropagation();
      event.preventDefault();
      this.add(null);
      const preventClick = function(event: MouseEvent) {
        event.preventDefault();
        window.removeEventListener("click", preventClick, true); //FIXME: add setTimeout to check mouse button status (if mousedown in browser and mouse up outside of browser and remove event listner if true)
      };
      window.addEventListener("click", preventClick, true);
    } else {
      if (
        target?.className === "contextMenu" ||
        target?.hasAttribute("disabled")
      ) {
        return;
      }
      const removeContextMenu = (event: MouseEvent) => {
        this.add(null);
        window.removeEventListener("click", removeContextMenu, false); //FIXME: add setTimeout to check mouse button status (if mousedown in browser and mouse up outside of browser and remove event listner if true)
      };
      window.addEventListener("click", removeContextMenu, false);
    }
    //console.log(this._items, ReactDOM.findDOMNode(this._instances[0]));
    //console.log(this._items.every(i => ReactDOM.findDOMNode(i).contains));
    //console.log(this._items.every(i => i.contains(e.target)));
  }

  componentDidMount() {
    const constructor = this.constructor as typeof ContextMenuManager;

    constructor._instances.push(this);
    if (constructor._instances.length === 1 && !constructor._onClickHandle) {
      constructor._onClickHandle = (event: MouseEvent) => constructor._onClick(event);
      window.addEventListener(
        "mousedown",
        constructor._onClickHandle,
        true
      ); //https://github.com/d3/d3-drag/issues/9
    }
  }

  componentWillUnmount() {
    const constructor = this.constructor as typeof ContextMenuManager;

    let index = constructor._instances.indexOf(this);
    constructor._instances.splice(index, 1);
    if (constructor._instances.length === 0 && constructor._onClickHandle) {
      window.removeEventListener("mousedown", constructor._onClickHandle, true);
      constructor._onClickHandle = null;
      constructor._max = 1;
      constructor.add(null);
    }
  }

  render() {
    const constructor = this.constructor as typeof ContextMenuManager;

    return constructor._items;
  }
}

export type ContextMenuProps = {
  x: number,
  y: number,
};

export class ContextMenu extends React.Component<ContextMenuProps> {
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
        className="contextMenu"
        style={{
          position: "absolute",
          left: this.props.x,
          top: this.props.y
        }}
      >
        {this.props.children}
      </div>
    );
    //return this.state.show ? <span>test</span> : null;
  }
}

export class ContextMenuItem extends React.Component {
  render() {
    return (
      <div className="contextMenuItem" {...this.props}>
        {this.props.children}
      </div>
    );
  }
}
