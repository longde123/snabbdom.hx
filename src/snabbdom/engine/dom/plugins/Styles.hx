package snabbdom.engine.dom.plugins;

import snabbdom.engine.dom.PatchDom.*;
import snabbdom.Is.*;
import snabbdom.engine.dom.plugins.Helpers.next_frame;
using snabbdom.VirtualNodeDataTools;

@:build(ClassicFor.build())
class Styles {

  inline static function raf(fn) js.Browser.window.requestAnimationFrame(fn);

  inline static function nextFrame(fn) raf(function(i) { raf(fn); });

  inline static function setNextFrame(obj:DynamicObject<Dynamic>, prop:String, val:Dynamic) {
    nextFrame(function(i) { obj[prop] = val; });
  }

  inline static function updateStyle(oldVnode:VirtualNodeDom, vnode:VirtualNodeDom) {
    var cur, name, elm:Dynamic = vnode.elm;

    var apply_styles = if (vnode.data.skip_styles == false) {
      true;
    } else {
      if (elm.cached_styles == null) {
        elm.cached_styles = true;
        true;
      } else {
        if (elm.cached_styles == true) {
          false;
        } else {
          true;
        }
      }
    };

    if (apply_styles) {
      var oldStyle = oldVnode.data.get_style_or_empty();
      var style = vnode.data.get_style_or_empty();
      var oldHasDel = oldStyle.exists('delayed' );
      for (name in style.keys()) {
        cur = style[name];
        if (name == 'delayed') {
          var delayed:DynamicObject<Dynamic> = untyped style.delayed;
          var oldDelayed:DynamicObject<Dynamic> = untyped oldStyle.delayed;
          for (name in delayed.keys()) {
            cur = delayed[name];
            if (!oldHasDel || cur != oldDelayed[name]) {
              setNextFrame(elm.style, name, cur);
            }
          }
        } else if (name != 'remove' && cur != oldStyle[name]) {
          next_frame(untyped elm.style[name] = cur);
        }
      }


    }
  }

  inline static function applyDestroyStyle(vnode:VirtualNodeDom) {
    var style:DynamicObject<Dynamic> = null, name, elm = vnode.elm, s:Dynamic = vnode.data.style;
    if (s == null) return;
    style = untyped s.destroy;
    if ( style == null ) return;
    for (name in style.keys()) {
      untyped elm.style[name] = style[name];
    }
  }

  inline static function applyRemoveStyle(vnode:VirtualNodeDom, rm) {
    var s:Dynamic = vnode.data.style;
    if (!s || !s.remove) {
      if (rm != null) rm() ;
      return;
    }
    var name, elm = vnode.elm, idx, i = 0, maxDur = 0,
        compStyle:DynamicObject<String>, style:DynamicObject<Dynamic> = s.remove, amount = 0, applied = [];
    for (name in style.keys()) {
      applied.push(name);
      untyped elm.style[name] = style[name];
    }
    compStyle = untyped js.Browser.window.getComputedStyle(untyped elm);
    var props = compStyle['transition-property'].split(', ');
    var i ;
    @for(i = 0, i < props.length, ++i) {
      if(applied.indexOf(props[i]) != -1) amount++;
    }
    untyped elm.addEventListener('transitionend', function(ev) {
      if (ev.target == elm) --amount;
      if (amount == 0) rm();
    });
  }

inline public static function create(oldVnode:VirtualNodeDom,vnode:VirtualNodeDom) updateStyle(oldVnode,vnode);
inline public static function update(oldVnode:VirtualNodeDom,vnode:VirtualNodeDom) updateStyle(oldVnode,vnode);
inline public static function destroy(vnode:VirtualNodeDom) applyDestroyStyle(vnode);
inline public static function remove(vnode:VirtualNodeDom,rm) applyRemoveStyle(vnode,rm);


}
