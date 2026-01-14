# WLJS JS support package
**An extension for [WLJS-Editor](https://github.com/JerryI/wljs-editor) to add JS type of cells...**

## Example

```js
.js

const element = document.createElement('span');

this.ondestroy = () => {
    alert('removed');
}

this.after = () => {
    alert('after');
    element.innerText = "Test!";
}

return element;
```

## License
Project is released under the GNU General Public License (GPL).
