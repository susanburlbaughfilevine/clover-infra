window.addEventListener("load", function() {

    /**
     * An example of customization of the Data Apps page.
     * 
     * Div element with a text is added at the bottom of the content div.
     * The JavaScript code will be executed after loading of the page.
     */
    const dataAppEl = this.document.querySelector(".content");
    const newEl = document.createElement("div");
    newEl.innerHTML = "Copyright © 2020 My Company, All rights reserved.";
    newEl.id = "footer";
    dataAppEl.parentNode.insertBefore(newEl, dataAppEl.nextSibling);

    // here you can insert your JavaScript code

}, false);
