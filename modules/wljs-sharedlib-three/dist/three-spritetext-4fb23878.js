import { CanvasTexture, Sprite, SpriteMaterial, SRGBColorSpace } from './three.module-494e6c91.js';

function _arrayLikeToArray(r, a) {
  (null == a || a > r.length) && (a = r.length);
  for (var e = 0, n = Array(a); e < a; e++) n[e] = r[e];
  return n;
}
function _arrayWithHoles(r) {
  if (Array.isArray(r)) return r;
}
function _arrayWithoutHoles(r) {
  if (Array.isArray(r)) return _arrayLikeToArray(r);
}
function _assertThisInitialized(e) {
  if (void 0 === e) throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  return e;
}
function _callSuper(t, o, e) {
  return o = _getPrototypeOf(o), _possibleConstructorReturn(t, _isNativeReflectConstruct() ? Reflect.construct(o, e || [], _getPrototypeOf(t).constructor) : o.apply(t, e));
}
function _classCallCheck(a, n) {
  if (!(a instanceof n)) throw new TypeError("Cannot call a class as a function");
}
function _defineProperties(e, r) {
  for (var t = 0; t < r.length; t++) {
    var o = r[t];
    o.enumerable = o.enumerable || !1, o.configurable = !0, "value" in o && (o.writable = !0), Object.defineProperty(e, _toPropertyKey(o.key), o);
  }
}
function _createClass(e, r, t) {
  return r && _defineProperties(e.prototype, r), Object.defineProperty(e, "prototype", {
    writable: !1
  }), e;
}
function _getPrototypeOf(t) {
  return _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function (t) {
    return t.__proto__ || Object.getPrototypeOf(t);
  }, _getPrototypeOf(t);
}
function _inherits(t, e) {
  if ("function" != typeof e && null !== e) throw new TypeError("Super expression must either be null or a function");
  t.prototype = Object.create(e && e.prototype, {
    constructor: {
      value: t,
      writable: !0,
      configurable: !0
    }
  }), Object.defineProperty(t, "prototype", {
    writable: !1
  }), e && _setPrototypeOf(t, e);
}
function _isNativeReflectConstruct() {
  try {
    var t = !Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
  } catch (t) {}
  return (_isNativeReflectConstruct = function () {
    return !!t;
  })();
}
function _iterableToArray(r) {
  if ("undefined" != typeof Symbol && null != r[Symbol.iterator] || null != r["@@iterator"]) return Array.from(r);
}
function _iterableToArrayLimit(r, l) {
  var t = null == r ? null : "undefined" != typeof Symbol && r[Symbol.iterator] || r["@@iterator"];
  if (null != t) {
    var e,
      n,
      i,
      u,
      a = [],
      f = !0,
      o = !1;
    try {
      if (i = (t = t.call(r)).next, 0 === l) {
        if (Object(t) !== t) return;
        f = !1;
      } else for (; !(f = (e = i.call(t)).done) && (a.push(e.value), a.length !== l); f = !0);
    } catch (r) {
      o = !0, n = r;
    } finally {
      try {
        if (!f && null != t.return && (u = t.return(), Object(u) !== u)) return;
      } finally {
        if (o) throw n;
      }
    }
    return a;
  }
}
function _nonIterableRest() {
  throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}
function _nonIterableSpread() {
  throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}
function _possibleConstructorReturn(t, e) {
  if (e && ("object" == typeof e || "function" == typeof e)) return e;
  if (void 0 !== e) throw new TypeError("Derived constructors may only return object or undefined");
  return _assertThisInitialized(t);
}
function _setPrototypeOf(t, e) {
  return _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function (t, e) {
    return t.__proto__ = e, t;
  }, _setPrototypeOf(t, e);
}
function _slicedToArray(r, e) {
  return _arrayWithHoles(r) || _iterableToArrayLimit(r, e) || _unsupportedIterableToArray(r, e) || _nonIterableRest();
}
function _toConsumableArray(r) {
  return _arrayWithoutHoles(r) || _iterableToArray(r) || _unsupportedIterableToArray(r) || _nonIterableSpread();
}
function _toPrimitive(t, r) {
  if ("object" != typeof t || !t) return t;
  var e = t[Symbol.toPrimitive];
  if (void 0 !== e) {
    var i = e.call(t, r);
    if ("object" != typeof i) return i;
    throw new TypeError("@@toPrimitive must return a primitive value.");
  }
  return (String )(t);
}
function _toPropertyKey(t) {
  var i = _toPrimitive(t, "string");
  return "symbol" == typeof i ? i : i + "";
}
function _unsupportedIterableToArray(r, a) {
  if (r) {
    if ("string" == typeof r) return _arrayLikeToArray(r, a);
    var t = {}.toString.call(r).slice(8, -1);
    return "Object" === t && r.constructor && (t = r.constructor.name), "Map" === t || "Set" === t ? Array.from(r) : "Arguments" === t || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t) ? _arrayLikeToArray(r, a) : void 0;
  }
}

var three = typeof window !== 'undefined' && window.THREE ? window.THREE // Prefer consumption from global THREE, if exists
: {
  CanvasTexture: CanvasTexture,
  Sprite: Sprite,
  SpriteMaterial: SpriteMaterial,
  SRGBColorSpace: SRGBColorSpace
};
var _default = /*#__PURE__*/function (_three$Sprite) {
  function _default() {
    var _this;
    var text = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';
    var textHeight = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 10;
    var color = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 'rgba(255, 255, 255, 1)';
    _classCallCheck(this, _default);
    _this = _callSuper(this, _default, [new three.SpriteMaterial()]);
    _this._text = "".concat(text);
    _this._textHeight = textHeight;
    _this._color = color;
    _this._backgroundColor = false; // no background color

    _this._padding = 0;
    _this._borderWidth = 0;
    _this._borderRadius = 0;
    _this._borderColor = 'white';
    _this._strokeWidth = 0;
    _this._strokeColor = 'white';
    _this._fontFace = 'system-ui';
    _this._fontSize = 90; // defines text resolution
    _this._fontWeight = 'normal';
    _this._canvas = document.createElement('canvas');
    _this._genCanvas();
    return _this;
  }
  _inherits(_default, _three$Sprite);
  return _createClass(_default, [{
    key: "text",
    get: function get() {
      return this._text;
    },
    set: function set(text) {
      this._text = text;
      this._genCanvas();
    }
  }, {
    key: "textHeight",
    get: function get() {
      return this._textHeight;
    },
    set: function set(textHeight) {
      this._textHeight = textHeight;
      this._genCanvas();
    }
  }, {
    key: "color",
    get: function get() {
      return this._color;
    },
    set: function set(color) {
      this._color = color;
      this._genCanvas();
    }
  }, {
    key: "backgroundColor",
    get: function get() {
      return this._backgroundColor;
    },
    set: function set(color) {
      this._backgroundColor = color;
      this._genCanvas();
    }
  }, {
    key: "padding",
    get: function get() {
      return this._padding;
    },
    set: function set(padding) {
      this._padding = padding;
      this._genCanvas();
    }
  }, {
    key: "borderWidth",
    get: function get() {
      return this._borderWidth;
    },
    set: function set(borderWidth) {
      this._borderWidth = borderWidth;
      this._genCanvas();
    }
  }, {
    key: "borderRadius",
    get: function get() {
      return this._borderRadius;
    },
    set: function set(borderRadius) {
      this._borderRadius = borderRadius;
      this._genCanvas();
    }
  }, {
    key: "borderColor",
    get: function get() {
      return this._borderColor;
    },
    set: function set(borderColor) {
      this._borderColor = borderColor;
      this._genCanvas();
    }
  }, {
    key: "fontFace",
    get: function get() {
      return this._fontFace;
    },
    set: function set(fontFace) {
      this._fontFace = fontFace;
      this._genCanvas();
    }
  }, {
    key: "fontSize",
    get: function get() {
      return this._fontSize;
    },
    set: function set(fontSize) {
      this._fontSize = fontSize;
      this._genCanvas();
    }
  }, {
    key: "fontWeight",
    get: function get() {
      return this._fontWeight;
    },
    set: function set(fontWeight) {
      this._fontWeight = fontWeight;
      this._genCanvas();
    }
  }, {
    key: "strokeWidth",
    get: function get() {
      return this._strokeWidth;
    },
    set: function set(strokeWidth) {
      this._strokeWidth = strokeWidth;
      this._genCanvas();
    }
  }, {
    key: "strokeColor",
    get: function get() {
      return this._strokeColor;
    },
    set: function set(strokeColor) {
      this._strokeColor = strokeColor;
      this._genCanvas();
    }
  }, {
    key: "_genCanvas",
    value: function _genCanvas() {
      var _this2 = this;
      var canvas = this._canvas;
      var ctx = canvas.getContext('2d');
      var border = Array.isArray(this.borderWidth) ? this.borderWidth : [this.borderWidth, this.borderWidth]; // x,y border
      var relBorder = border.map(function (b) {
        return b * _this2.fontSize * 0.1;
      }); // border in canvas units

      var borderRadius = Array.isArray(this.borderRadius) ? this.borderRadius : [this.borderRadius, this.borderRadius, this.borderRadius, this.borderRadius]; // tl tr br bl corners
      var relBorderRadius = borderRadius.map(function (b) {
        return b * _this2.fontSize * 0.1;
      }); // border radius in canvas units

      var padding = Array.isArray(this.padding) ? this.padding : [this.padding, this.padding]; // x,y padding
      var relPadding = padding.map(function (p) {
        return p * _this2.fontSize * 0.1;
      }); // padding in canvas units

      var lines = this.text.split('\n');
      var font = "".concat(this.fontWeight, " ").concat(this.fontSize, "px ").concat(this.fontFace);
      ctx.font = font; // measure canvas with appropriate font
      var innerWidth = Math.max.apply(Math, _toConsumableArray(lines.map(function (line) {
        return ctx.measureText(line).width;
      })));
      var innerHeight = this.fontSize * lines.length;
      canvas.width = innerWidth + relBorder[0] * 2 + relPadding[0] * 2;
      canvas.height = innerHeight + relBorder[1] * 2 + relPadding[1] * 2;

      // paint border
      if (this.borderWidth) {
        ctx.strokeStyle = this.borderColor;
        if (relBorder[0]) {
          // left + right borders
          var hb = relBorder[0] / 2;
          ctx.lineWidth = relBorder[0];
          ctx.beginPath();
          ctx.moveTo(hb, relBorderRadius[0]);
          ctx.lineTo(hb, canvas.height - relBorderRadius[3]);
          ctx.moveTo(canvas.width - hb, relBorderRadius[1]);
          ctx.lineTo(canvas.width - hb, canvas.height - relBorderRadius[2]);
          ctx.stroke();
        }
        if (relBorder[1]) {
          // top + bottom borders
          var _hb = relBorder[1] / 2;
          ctx.lineWidth = relBorder[1];
          ctx.beginPath();
          ctx.moveTo(Math.max(relBorder[0], relBorderRadius[0]), _hb);
          ctx.lineTo(canvas.width - Math.max(relBorder[0], relBorderRadius[1]), _hb);
          ctx.moveTo(Math.max(relBorder[0], relBorderRadius[3]), canvas.height - _hb);
          ctx.lineTo(canvas.width - Math.max(relBorder[0], relBorderRadius[2]), canvas.height - _hb);
          ctx.stroke();
        }
        if (this.borderRadius) {
          // strike rounded corners
          var cornerWidth = Math.max.apply(Math, _toConsumableArray(relBorder));
          var _hb2 = cornerWidth / 2;
          ctx.lineWidth = cornerWidth;
          ctx.beginPath();
          [!!relBorderRadius[0] && [relBorderRadius[0], _hb2, _hb2, relBorderRadius[0]], !!relBorderRadius[1] && [canvas.width - relBorderRadius[1], canvas.width - _hb2, _hb2, relBorderRadius[1]], !!relBorderRadius[2] && [canvas.width - relBorderRadius[2], canvas.width - _hb2, canvas.height - _hb2, canvas.height - relBorderRadius[2]], !!relBorderRadius[3] && [relBorderRadius[3], _hb2, canvas.height - _hb2, canvas.height - relBorderRadius[3]]].filter(function (d) {
            return d;
          }).forEach(function (_ref) {
            var _ref2 = _slicedToArray(_ref, 4),
              x0 = _ref2[0],
              x1 = _ref2[1],
              y0 = _ref2[2],
              y1 = _ref2[3];
            ctx.moveTo(x0, y0);
            ctx.quadraticCurveTo(x1, y0, x1, y1);
          });
          ctx.stroke();
        }
      }

      // paint background
      if (this.backgroundColor) {
        ctx.fillStyle = this.backgroundColor;
        if (!this.borderRadius) {
          ctx.fillRect(relBorder[0], relBorder[1], canvas.width - relBorder[0] * 2, canvas.height - relBorder[1] * 2);
        } else {
          // fill with rounded corners
          ctx.beginPath();
          ctx.moveTo(relBorder[0], relBorderRadius[0]);
          [[relBorder[0], relBorderRadius[0], canvas.width - relBorderRadius[1], relBorder[1], relBorder[1], relBorder[1]],
          // t
          [canvas.width - relBorder[0], canvas.width - relBorder[0], canvas.width - relBorder[0], relBorder[1], relBorderRadius[1], canvas.height - relBorderRadius[2]],
          // r
          [canvas.width - relBorder[0], canvas.width - relBorderRadius[2], relBorderRadius[3], canvas.height - relBorder[1], canvas.height - relBorder[1], canvas.height - relBorder[1]],
          // b
          [relBorder[0], relBorder[0], relBorder[0], canvas.height - relBorder[1], canvas.height - relBorderRadius[3], relBorderRadius[0]] // t
          ].forEach(function (_ref3) {
            var _ref4 = _slicedToArray(_ref3, 6),
              x0 = _ref4[0],
              x1 = _ref4[1],
              x2 = _ref4[2],
              y0 = _ref4[3],
              y1 = _ref4[4],
              y2 = _ref4[5];
            ctx.quadraticCurveTo(x0, y0, x1, y1);
            ctx.lineTo(x2, y2);
          });
          ctx.closePath();
          ctx.fill();
        }
      }
      ctx.translate.apply(ctx, _toConsumableArray(relBorder));
      ctx.translate.apply(ctx, _toConsumableArray(relPadding));

      // paint text
      ctx.font = font; // Set font again after canvas is resized, as context properties are reset
      ctx.fillStyle = this.color;
      ctx.textBaseline = 'bottom';
      var drawTextStroke = this.strokeWidth > 0;
      if (drawTextStroke) {
        ctx.lineWidth = this.strokeWidth * this.fontSize / 10;
        ctx.strokeStyle = this.strokeColor;
      }
      lines.forEach(function (line, index) {
        var lineX = (innerWidth - ctx.measureText(line).width) / 2;
        var lineY = (index + 1) * _this2.fontSize;
        drawTextStroke && ctx.strokeText(line, lineX, lineY);
        ctx.fillText(line, lineX, lineY);
      });

      // Inject canvas into sprite
      if (this.material.map) this.material.map.dispose(); // gc previous texture
      var texture = this.material.map = new three.CanvasTexture(canvas);
      texture.colorSpace = three.SRGBColorSpace;
      var yScale = this.textHeight * lines.length + border[1] * 2 + padding[1] * 2;
      this.scale.set(yScale * canvas.width / canvas.height, yScale, 0);
    }
  }, {
    key: "clone",
    value: function clone() {
      return new this.constructor(this.text, this.textHeight, this.color).copy(this);
    }
  }, {
    key: "copy",
    value: function copy(source) {
      three.Sprite.prototype.copy.call(this, source);
      this.color = source.color;
      this.backgroundColor = source.backgroundColor;
      this.padding = source.padding;
      this.borderWidth = source.borderWidth;
      this.borderColor = source.borderColor;
      this.fontFace = source.fontFace;
      this.fontSize = source.fontSize;
      this.fontWeight = source.fontWeight;
      this.strokeWidth = source.strokeWidth;
      this.strokeColor = source.strokeColor;
      return this;
    }
  }]);
}(three.Sprite);

export { _default as default };
