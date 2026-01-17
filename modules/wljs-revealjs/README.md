# RevealJS Plugin
*An extension for [WLJS Frontend](https://github.com/JerryI/wolfram-js-frontend) that allows you to make slides and an entire presentation using Markdown, HTML, JS, Wolfram Language or WLX*


*if you have __no idea about__ titles mentioned, __please visit [the official page](https://github.com/JerryI/wolfram-js-frontend)__ ;)*

The core library is [RevealJS](https://revealjs.com), that is running in Markdown mode.

![](imgs/ezgif.com-optimize-15.gif)

see the [**full demo**](https://youtu.be/7cEYJG7nk7U?si=IzYInhddG66pNUHp)

> This README __does not cover all features__. Please read [docs](https://jerryi.github.io/wljs-docs/)


## Making slides using Markdown

To create a slide type in a new cell

```markdown
.slide

# Title
Paragraph 1

---

# Second slide

Paragraph 2

<div style="color: red">with some HTML</div>
```

![](imgs/Screenshot%202023-09-01%20at%2018.40.15.png)

The output can be projected into a separate window for the convinience. 

## Merging slides from a different cells
To merge the all slides into a single fat presentation use

```markdown
.slides

```
It will merge and print slides from all cells in the notebook into a single one.

## Embed Wolfram Language
The real power comes, if you are using __[WLX addon](https://jerryi.github.io/wljs-docs/wlx)__, which is shipped as a separate plugin [wljs-wlx-support](https://github.com/JerryI/wljs-wlx-support) allowing you to write in WL language XML-like style

*first cell*
```mathematica
Figure = Plot[x, {x, 0, 1}];
```

*second cell*
```markdown
.slide

# Embedded Wolfram

<TextString><Now/></TextString>

Or even some graphics, like

<div style="text-align: center">
    <Figure/>
</div>
```

![](imgs/Screenshot%202023-09-01%20at%2018.41.08.png)



## Packages used

✨ Thank these amazing people  ✨

- [Reveal](https://revealjs.com)
- [katex](https://katex.org/)
- [marked](https://marked.js.org/using_advanced#options)
- [mathjax3](https://www.mathjax.org/)
- [latexanimation](https://github.com/CianLM/reveal-animated-latex) 
- [pointer](https://github.com/burnpiro/reveal-pointer) (use `q` to toggle) 



## Installation
already a core component!

## License
Project is released under the GNU General Public License (GPL).
