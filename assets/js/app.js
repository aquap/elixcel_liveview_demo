// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";

let Hooks = {};

Hooks.SetFocus = {
  mounted() {
    this.el.focus();
    this.el.selectionStart = this.el.selectionEnd = this.el.value.length;
  }
};

// A bunch of keys are handled by the Elixcel live view and we do not
// want to also send those to the browser
document.addEventListener("keydown", event => {
  if (
    event.key == "ArrowUp" ||
    event.key == "ArrowDown" ||
    event.key == "ArrowLeft" ||
    event.key == "ArrowRight" ||
    event.key == "Tab" ||
    (event.metaKey && event.key == "b") ||
    (event.ctrlKey && event.key == "b") ||
    (event.metaKey && event.key == "i") ||
    (event.ctrlKey && event.key == "i")
  ) {
    event.preventDefault();
  }

  // Only send Backspace to the browser when editing
  if ((event.key == "Backspace") && document.querySelectorAll('table[editing]').length == 0) {
    event.preventDefault();
  }
});

let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks });
liveSocket.connect();
