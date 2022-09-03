import React from "react";
import ReactDOM from "react-dom";
import MaterialIcon from "./MaterialIcon.jsx";
import "./ToastContainer.css";

export type ToastContainerProps = {
  style?: React.DetailedHTMLProps<React.StyleHTMLAttributes<HTMLStyleElement>, HTMLStyleElement>,
};

export default class ToastContainer extends React.Component<ToastContainerProps> {
    /** instances of active toasts. */
    static _items:JSX.Element[] = [];
    /** instances of self. */
    static _instances: ToastContainer[] = [];
    /** @deprecated does not seem to be called anywhere. */
    static _onClickHandle: null|((event: MouseEvent) => void);
    static _AUTO_INCREMENT = 0;

    //FIXME: setting _max > 1 results in bad handling when removing context menu
    /** The max ammount of context menus allowed at the same time. */
    static _max: number = 5;

    static getAutoIncrement() {
        return this._AUTO_INCREMENT;
    }

    static setMax(max: number) {
        this._max = max;
    }
    
    static add(data: any, className: string|null = null) {
        while (this._items.length >= this._max && this._items.length > 0) {
          this._items.shift(); //TODO: maybe use slice instead, to avoid the loop.
        }
        let key = this._AUTO_INCREMENT;
        if (data) {
            let key = this._AUTO_INCREMENT++;
            this._items.push(
                <Toast key={key} className={className ?? undefined}>
                    {data}
                </Toast>
            );
        }
        this.refreshInstances();
        return key;
    }
    
    static remove(key: React.Key) {
        let index = this._items.findIndex(i => i.key === key);
        if (index !== -1) this._items.splice(index, 1);
        this.refreshInstances();
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
            // window.removeEventListener("click", preventClick, true);
          };
          // window.addEventListener("click", preventClick, true);
        } else {
          if (
            target?.className === "toast" ||
            target?.hasAttribute("disabled")
          ) {
            return;
          }
          const removeContextMenu = (event: MouseEvent) => {
            this.add(null);
            // window.removeEventListener("click", removeContextMenu, false);
          };
          // window.addEventListener("click", removeContextMenu, false);
        }
        //console.log(this._items, ReactDOM.findDOMNode(this._instances[0]));
        //console.log(this._items.every(i => ReactDOM.findDOMNode(i).contains));
        //console.log(this._items.every(i => i.contains(e.target)));
    }
    
    componentDidMount() {
        const constructor = this.constructor as typeof ToastContainer;

        constructor._instances.push(this);
        if (constructor._instances.length === 1 && !constructor._onClickHandle) {
          constructor._onClickHandle = event => constructor._onClick(event);
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
        const constructor = this.constructor as typeof ToastContainer;

        let index = constructor._instances.indexOf(this);
        constructor._instances.splice(index, 1);
        if (constructor._instances.length === 0 && constructor._onClickHandle) {
          //window.removeEventListener("mousedown", this._onClickHandle, true);
          constructor._onClickHandle = null;
          constructor._max = 1;
          constructor.add(null);
        }
    }
    
    render() {
        return <div style={{position: "absolute", right: "30px", bottom: "10px", display: "flex", flexDirection: "column", gap: "5px", ...this.props.style}}>{(this.constructor as typeof ToastContainer)._items}</div>;
    }
}

export type ToastProps = {
  className?: string | undefined;
}

export type ToastState = {
  show: boolean,
}

/** @deprecated Internal react object, could be changed at anytime without warning! */
interface ReactInternals {
  key: React.Key;
};

export class Toast extends React.Component<ToastProps, ToastState> {
    state: Readonly<ToastState> = {
      show: false
    };

    /** @deprecated Internal react object, could be changed at anytime without warning! */
    // @ts-ignore: No initializer and is not definitely assigned in the constructor.
    _reactInternals: ReactInternals;
  
    constructor(props: Readonly<ToastProps> | ToastProps) {
      super(props);
    }

    getKey(): React.Key {
        return this._reactInternals.key;
    }

    onClick = () => {
        ToastContainer.remove(this.getKey());
    }

    render() {
        const className = ["toast", this.props.className].filter(v => v).join(" ");

        return (
            <div
            className={className}
            /*style={{
                position: "absolute",
                left: this.props.x,
                top: this.props.y
            }}*/
            >
                <MaterialIcon icon="close" className="close" onClick={this.onClick} />
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
