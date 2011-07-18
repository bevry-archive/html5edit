(function() {
  $(function() {
    $.fn.enter = $.fn.enter || function(data, callback) {
      return $(this).binder("enter", data, callback);
    };
    $.event.special.enter = {
      setup: function(data, namespaces) {
        return $(this).bind("keypress", $.event.special.enter.handler);
      },
      teardown: function(namespaces) {
        return $(this).unbind("keypress", $.event.special.enter.handler);
      },
      handler: function(event) {
        var $el, enterKey;
        $el = $(this);
        enterKey = event.keyCode === 13;
        if (enterKey) {
          event.type = "enter";
          $.event.handle.apply(this, [event]);
          return true;
        }
      }
    };
    return $('[contenteditable]').live('focus', function() {
      var $this;
      $this = $(this);
      $this.data('before', $this.html());
      return $this;
    }).live('blur keyup paste', function() {
      var $this, html;
      $this = $(this);
      html = $this.html();
      if ($this.data('before') !== html) {
        $this.data('before', html);
        $this.trigger('change');
      }
      return $this;
    }).live('enter', function() {
      var $sel, $this, cleaner;
      $this = $(this);
      $sel = $this.htmlSelectionRange();
      return cleaner = function() {
        var $new, $p, found;
        $this.find(':has(> br:first-child:last-child)').replaceWith('<p class="new p">&nbsp;&nbsp;</p>');
        found = true;
        while (found) {
          $p = $this.find('p.p > p.p');
          $p.appendTo($p.parent());
          found = $p.length;
        }
        $new = $this.find('p.p.new');
        if ($new.length === 1) {
          return $new.htmlSelectionRange(1, 1).removeClass('new');
        }
      };
    });
  });
}).call(this);
(function() {
  var generateToken, inlineElements, spaceEntities;
  inlineElements = ['strong', 'b', 'u', 'em', 'i', 'del', 'ins'];
  spaceEntities = ['\\s', '&nbsp;'];
  generateToken = function() {
    return '!!' + Math.random() + '!!';
  };
  String.prototype.selectableLength = function() {
    var html, text;
    html = this.toString();
    text = html.replace(/(\&[0-9a-zA-Z]+\;)/g, ' ');
    return text.length;
  };
  String.prototype.textToHtmlIndex = function(index) {
    var elementFirstRegex, elementRegex, entityFirstRegex, entityRegex, html, htmlIndex, htmlPart, htmlParts, i, ii, textIndex, textPart, textParts, _len, _len2;
    html = this.toString();
    textIndex = 0;
    htmlIndex = 0;
    entityRegex = /(\&[0-9a-zA-Z]+\;)/g;
    elementRegex = /(\<[0-9a-zA-Z]+\>)/g;
    elementFirstRegex = /^\<[0-9a-zA-Z]+\>/;
    entityFirstRegex = /^\&[0-9a-zA-Z]+\;/;
    htmlParts = html.split(/<|>/g);
    for (i = 0, _len = htmlParts.length; i < _len; i++) {
      htmlPart = htmlParts[i];
      if ((i % 2) === 1) {
        htmlIndex += htmlPart.length + 2;
      } else {
        textParts = htmlPart.replace(entityRegex, '<$1>').split(/<|>/g);
        for (ii = 0, _len2 = textParts.length; ii < _len2; ii++) {
          textPart = textParts[ii];
          htmlIndex += textPart.length;
          if ((ii % 2) === 1) {
            textIndex += 1;
            if (textIndex > index) {
              break;
            }
          } else {
            textIndex += textPart.length;
            if (textIndex > index) {
              htmlIndex -= textIndex - index;
              break;
            }
          }
        }
        if (textIndex > index) {
          break;
        }
      }
    }
    return htmlIndex;
  };
  String.prototype.htmlToTextIndex = function(htmlIndex) {
    var $html, html, textIndex, token;
    html = this.toString();
    token = generateToken();
    $html = $(html.substring(0, htmlIndex) + token + html.substring(htmlIndex));
    textIndex = $html.text().indexOf(token);
    return textIndex;
  };
  String.prototype.getTextIndexDepth = function(index) {
    var htmlIndex;
    htmlIndex = this.textToHtmlIndex(index);
    return this.getHtmlIndexDepth(htmlIndex);
  };
  String.prototype.getHtmlIndexDepth = function(index) {
    var depthIndex, htmlIndex, i, part, parts, _len;
    parts = this.split(/<|>/g);
    depthIndex = 0;
    htmlIndex = 0;
    depthIndex = 0;
    for (i = 0, _len = parts.length; i < _len; i++) {
      part = parts[i];
      if (i) {
        htmlIndex++;
      }
      htmlIndex += part.length;
      if (i % 2) {
        if (part.length) {
          if (part[0] === '/') {
            --depthIndex;
          } else {
            ++depthIndex;
          }
        }
      }
      if (htmlIndex >= index) {
        break;
      }
    }
    return depthIndex;
  };
  String.prototype.levelTextIndexes = function(start, finish) {
    var finishIndex, startIndex;
    startIndex = this.textToHtmlIndex(start);
    finishIndex = this.textToHtmlIndex(finish);
    return this.levelHtmlIndexes(startIndex, finishIndex);
  };
  String.prototype.levelHtmlIndexes = function(start, finish) {
    var finishDepth, finishIndex, i, n, startDepth, startIndex;
    if (startIndex > finishIndex) {
      throw new Error('Start greater than finish!');
    }
    startIndex = start;
    finishIndex = finish;
    startDepth = this.getHtmlIndexDepth(startIndex);
    finishDepth = this.getHtmlIndexDepth(finishIndex);
    if (startDepth > finishDepth) {
      n = startDepth - finishDepth;
      for (i = 0; 0 <= n ? i < n : i > n; 0 <= n ? i++ : i--) {
        startIndex = this.lastIndexOf('<', startIndex - 1);
      }
    } else if (finishDepth > startDepth) {
      n = finishDepth - startDepth;
      n = startDepth - finishDepth;
      for (i = 0; 0 <= n ? i < n : i > n; 0 <= n ? i++ : i--) {
        finishIndex = this.indexOf('>', finishIndex + 1) + 1;
      }
    }
    return [startIndex, finishIndex];
  };
  $.fn.textSlice = function(start, finish) {
    var finishIndex, startIndex, _ref;
    _ref = html.levelTextIndexes(start, finish), startIndex = _ref[0], finishIndex = _ref[1];
    return $(this).htmlSlice(startIndex, finishIndex);
  };
  $.fn.htmlSlice = function(start, finish) {
    var $el, $slice, $this, clone, finishIndex, html, startIndex, wrappedHtml, _ref;
    $this = $(this);
    clone = $this.data('slice-clone') || true;
    $el = clone ? $this.clone() : $this;
    html = $el.html();
    if (!html) {
      return $el;
    }
    if (start > finish) {
      throw new Error('$.fn.slice was passed a start index greater than the finish index');
    }
    if (((start != null) && (finish != null)) !== true) {
      throw new Error('$.fn.slice was passed incorrect indexes');
    }
    _ref = html.levelHtmlIndexes(start, finish), startIndex = _ref[0], finishIndex = _ref[1];
    if (((startIndex != null) && (finishIndex != null)) !== true) {
      throw new Error('$.fn.slice could not level indexes');
    }
    if ((startIndex != null) && (finishIndex != null)) {
      wrappedHtml = html.substring(0, startIndex) + '<span class="slice new">' + html.substring(startIndex, finishIndex) + '</span>' + html.substring(finishIndex);
      $slice = $el.html(wrappedHtml).find('span.slice.new');
      if (wrappedHtml !== $el.html()) {
        console.log(wrappedHtml);
        console.log($el.html());
        console.warn(new Error('slice was not applied as expected'));
      }
      $slice.removeClass('new');
    } else {
      $slice = $el;
    }
    if (clone) {
      $slice.data('slice-parent-old', $this).data('slice-parent-new', $el);
    }
    return $slice;
  };
  $.fn.puke = function() {
    var $this;
    $this = $(this);
    $this.replaceWith($this.html());
    return $this;
  };
  $.fn.cleanSlices = function() {
    var $slice, $this;
    $this = $(this);
    while (true) {
      $slice = $this.find('.slice:first');
      if ($slice.length === 0) {
        break;
      }
      $slice.puke();
    }
    return $this;
  };
  $.fn.apply = function() {
    var $originalNew, $originalOld, $slice;
    $slice = $(this).addClass('apply');
    $originalOld = $slice.data('slice-parent-old');
    $originalNew = $slice.data('slice-parent-new');
    if (!$originalOld || !$originalNew) {
      return $slice;
    }
    $originalOld.empty().append($originalNew.contents());
    return $slice;
  };
  $.fn.cleanNeighbours = function() {
    var $this, html, htmlNew, inlineElementsRegex;
    $this = $(this);
    inlineElementsRegex = new RegExp('(</(' + inlineElements.join('|') + ')>)' + '(' + spaceEntities.join('|') + ')' + '<\\2>', 'gi');
    html = $this.html();
    while (true) {
      htmlNew = html.replace(inlineElementsRegex, ' ');
      if (htmlNew === html) {
        break;
      } else {
        html = htmlNew;
      }
    }
    return $this.html(html);
  };
  $.fn.clean = function() {
    var $this, element, html, parts, selectionRange, tokenEnd, tokenEndIndex, tokenStart, tokenStartIndex, _i, _len;
    $this = $(this);
    selectionRange = $this.htmlSelectionRange();
    if (selectionRange) {
      tokenStart = generateToken();
      tokenEnd = generateToken();
      html = $this.html();
      html = html.substring(0, selectionRange.selectionStart) + tokenStart + html.substring(selectionRange.selectionStart, selectionRange.selectionEnd) + tokenEnd + html.substring(selectionRange.selectionEnd);
      $this.html(html);
    }
    $this.cleanSlices();
    for (_i = 0, _len = inlineElements.length; _i < _len; _i++) {
      element = inlineElements[_i];
      $this.find(element).find(element).puke();
    }
    $this.cleanNeighbours();
    if (selectionRange) {
      html = $this.html();
      tokenStartIndex = html.indexOf(tokenStart);
      tokenEndIndex = html.indexOf(tokenEnd);
      parts = [html.substring(0, tokenStartIndex), html.substring(tokenStartIndex + tokenStart.length, tokenEndIndex), html.substring(tokenEndIndex + tokenEnd.length)];
      if (parts[2].length && /^\<\/(div|p)/.test(parts[2])) {
        parts[2] = ' ' + parts[2];
      }
      $this.html(parts.join(''));
      console.log('two');
      console.log(html);
      console.log($this.html());
      selectionRange.selectionStart = tokenStartIndex;
      selectionRange.selectionEnd = tokenEndIndex - tokenStart.length;
      console.log(html, selectionRange);
      $this.htmlSelectionRange(selectionRange);
    }
    return $this;
  };
}).call(this);
(function() {
  $.fn.same = function(b) {
    var a;
    a = $(this);
    b = $(b);
    return a.get(0) === b.get(0);
  };
  $.fn.outerHtml = $.fn.outerHtml || function() {
    var $el, el, outerHtml;
    $el = $(this);
    el = $el.get(0);
    outerHtml = el.outerHTML || new XMLSerializer().serializeToString(el);
    return outerHtml;
  };
  $.fn.element = function() {
    var $el, el;
    $el = $(this);
    el = $el.get(0);
    if (el) {
      while (el.nodeType === 3) {
        el = el.parentNode;
      }
      $el = $(el);
    } else {
      $el = $();
    }
    return $el;
  };
  $.fn.includes = function(container) {
    var $container, $el, el, result;
    $el = $(this);
    el = $el.get(0);
    $container = $(container);
    container = $container.get(0);
    result = ($el.contents().filter($container).length ? 'child' : $el.find($container).length || $el.find($container.element()).length || $el.contents().filter($container.element()).length ? 'deep' : $el.same($container) ? 'same' : false);
    return result;
  };
  $.fn.elementStartLength = function() {
    var $this, outerHtml, result;
    $this = $(this);
    outerHtml = $this.outerHtml();
    return result = outerHtml && outerHtml[0] === '<' ? outerHtml.replace(/>.+$/g, '>').length : 0;
  };
  $.fn.elementEndLength = function() {
    var $this, outerHtml, result;
    $this = $(this);
    outerHtml = $this.outerHtml();
    return result = outerHtml && outerHtml[0] === '<' ? outerHtml.replace(/^.+</g, '<').length : 0;
  };
  $.fn.isElement = function() {
    var $this, outerHtml;
    $this = $(this);
    outerHtml = $this.outerHtml();
    return outerHtml && outerHtml[0] === '<';
  };
  $.fn.rawHtml = function() {
    var $this, outerHtml, result;
    $this = $(this);
    outerHtml = $this.outerHtml();
    return result = outerHtml && outerHtml[0] === '<' ? $this.html() : outerHtml;
  };
  $.fn.nextContent = function(recurse) {
    var $a, current, exit, found;
        if (recurse != null) {
      recurse;
    } else {
      recurse = true;
    };
    $a = $(this);
    current = $a;
    exit = false;
    found = false;
    $a.parent().contents().each(function() {
      var $b;
      $b = $(this);
      current = $b;
      if (exit) {
        found = true;
        return false;
      }
      if ($b.same($a)) {
        return exit = true;
      }
    });
    if (found === false) {
      current = $a.parent().nextContent(false);
    }
    return $(current);
  };
  $.fn.getNodeHtmlOffset = function(htmlIndex) {
    var $contents, $next, $parent, html, htmlLength, offset, parent, result, selectableLength;
    $parent = $(this);
    parent = $parent.get(0);
    $contents = $parent.contents();
    result = null;
    offset = 0;
    $contents.each(function() {
      var $container, container, htmlLength, localOffset, startLength;
      $container = $(this);
      container = $container.get(0);
      htmlLength = $container.rawHtml().length;
      startLength = $container.elementStartLength();
      offset += startLength;
      if (offset >= htmlIndex) {
        offset -= offset - htmlIndex;
        localOffset = htmlIndex - offset;
        if (container.nodeType === 3) {
          result = [container, localOffset];
          return false;
        } else {
          result = $container.getNodeHtmlOffset(localOffset);
          if (result == null) {
            result = [container, localOffset];
          }
          return false;
        }
      } else {
        offset += htmlLength;
        if (offset > htmlIndex) {
          result = $container.getNodeHtmlOffset(htmlLength - (offset - htmlIndex));
          return false;
        } else {
          offset += $container.elementEndLength();
        }
      }
      return true;
    });
    if (result == null) {
      html = $parent.rawHtml();
      htmlLength = html.length;
      selectableLength = html.selectableLength();
      if (htmlLength < htmlIndex) {
        result = [parent, htmlLength];
      } else if (htmlLength === htmlIndex) {
        $next = $parent.nextContent();
        if ($next.length !== 0) {
          result = [$next.get(0), 0];
        }
      } else {
        htmlIndex -= htmlLength - selectableLength;
        result = [parent, htmlIndex];
      }
    }
    return result;
  };
  $.fn.expandHtmlOffset = function(container, offset) {
    var $container, $parent, includes, parent, result;
    $parent = $(this);
    parent = $parent.get(0);
    $container = $(container);
    container = $container.get(0);
    result = 0;
    includes = $parent.includes($container);
    if (includes === 'same') {
      result = $parent.elementStartLength() + offset;
    } else if (includes) {
      $parent.contents().each(function() {
        var $el, el;
        $el = $(this);
        el = $el.get(0);
        if ($el.same($container)) {
          result += offset + $el.elementStartLength();
          return false;
        } else if ((el.nodeType === 3) || !$el.includes($container)) {
          result += ($el.outerHtml() || $el.html() || $el.text()).length;
          return true;
        } else {
          result += $el.elementStartLength() + $el.expandHtmlOffset(container, offset);
          return false;
        }
      });
    } else {
      throw new Error('The child does not exist in the parent');
    }
    return result;
  };
  $.fn.htmlSelectionRange = function(selectionRange) {
    var $el, $end, $parent, $start, el, endIndex, endNode, endOffset, parent, range, result, selection, selectionEnd, selectionStart, startIndex, startNode, startOffset, _ref, _ref2;
    $el = $(this);
    el = $el.get(0);
    result = this;
    if (typeof selectionRange === 'number') {
      if (arguments.length === 2) {
        selectionRange = {
          selectionStart: arguments[0],
          selectionEnd: arguments[1]
        };
      } else {
        selectionRange = {
          selectionStart: arguments[0],
          selectionEnd: arguments[0]
        };
      }
    }
    if ($el.is('textarea')) {
      if (selectionRange != null) {
        el.selectionStart = selectionRange.selectionStart;
        el.selectionEnd = selectionRange.selectionEnd;
        result = this;
      } else {
        selectionRange = {
          selectionStart: el.selectionStart,
          selectionEnd: el.selectionEnd
        };
        result = selectionRange;
      }
    } else {
      if (selectionRange != null) {
        if (!el) {
          return $el;
        }
        selection = window.getSelection();
        selection.removeAllRanges();
        range = document.createRange();
        if ($el.text().length) {
          _ref = $el.getNodeHtmlOffset(selectionRange.selectionStart), startNode = _ref[0], startOffset = _ref[1];
          _ref2 = $el.getNodeHtmlOffset(selectionRange.selectionEnd), endNode = _ref2[0], endOffset = _ref2[1];
          range.setStart(startNode, startOffset);
          range.setEnd(endNode, endOffset);
          console.log(endNode, endOffset, selectionRange.selectionEnd);
        }
        selection.addRange(range);
        result = this;
      } else {
        selection = window.getSelection();
        if (!selection.rangeCount) {
          return null;
        }
        range = selection.getRangeAt(0);
        parent = range.commonAncestorContainer;
        while (parent.nodeType === 3) {
          parent = parent.parentNode;
        }
        $parent = $(parent);
        try {
          if (true) {
            $start = $(range.startContainer).element();
            startOffset = $start.text().indexOf($(range.startContainer).text());
            startIndex = $start.html().textToHtmlIndex(startOffset + range.startOffset);
            selectionStart = $el.expandHtmlOffset($start, startIndex);
          } else {
            selectionStart = $el.expandHtmlOffset(range.startContainer, range.startOffset);
          }
          if (true) {
            $end = $(range.endContainer).element();
            endOffset = $end.text().indexOf($(range.endContainer).text());
            endIndex = $end.html().textToHtmlIndex(endOffset + range.endOffset);
            selectionEnd = $el.expandHtmlOffset($end, endIndex);
          } else {
            selectionEnd = $el.expandHtmlOffset(range.endContainer, range.endOffset);
          }
          selectionRange = {
            selectionStart: selectionStart,
            selectionEnd: selectionEnd
          };
          result = selectionRange;
        } catch (err) {
          result = null;
        }
      }
    }
    return result;
  };
  $.fn.htmlSelection = function(selectionRange) {
    var $el, $slice, el;
    $el = $(this);
    el = $el.get(0);
    if (selectionRange != null) {
      $el.htmlSelectionRange(selectionRange);
    } else {
      selectionRange = $el.htmlSelectionRange();
    }
    if (selectionRange != null) {
      $slice = $el.htmlSlice(selectionRange.selectionStart, selectionRange.selectionEnd);
    } else {
      $slice = $();
    }
    return $slice;
  };
  $.fn.select = function(all) {
    var $el, selectionRange;
    $el = $(this);
    all || (all = false);
    selectionRange = {
      selectionStart: 0,
      selectionEnd: all ? $el.rawHtml().length : 0
    };
    $el.htmlSelectionRange(selectionRange);
    if ($el.is('input')) {
      $el.focus();
    } else {
      $el.parents('#content').contents().focus();
    }
    return $el;
  };
}).call(this);
(function() {
  var _base, _base2, _ref, _ref2;
    if ((_ref = (_base = $.fn).firedPromiseEvent) != null) {
    _ref;
  } else {
    _base.firedPromiseEvent = function(eventName) {
      var $el, result;
      $el = $(this);
      result = ($el.data('defer-' + eventName + '-resolved') ? true : false);
      return result;
    };
  };
    if ((_ref2 = (_base2 = $.fn).createPromiseEvent) != null) {
    _ref2;
  } else {
    _base2.createPromiseEvent = function(eventName) {
      var $this, boundHandlers, events;
      $this = $(this);
      if (typeof $this.data('defer-' + eventName + '-resolved') !== 'undefined') {
        return $this;
      }
      $this.data('defer-' + eventName + '-resolved', false);
      events = $.fn.createPromiseEvent.events = $.fn.createPromiseEvent.events || {
        bind: function(callback) {
          $this = $(this);
          return $this.bind(eventName, callback);
        },
        trigger: function(event) {
          var Deferred, specialEvent;
          $this = $(this);
          Deferred = $this.data('defer-' + eventName);
          if (!Deferred) {
            specialEvent = $.event.special[eventName];
            specialEvent.setup.call(this);
            Deferred = $this.data('defer-' + eventName);
          }
          $this.data('defer-' + eventName + '-resolved', true);
          Deferred.resolve();
          event.preventDefault();
          event.stopImmediatePropagation();
          event.stopPropagation();
          return $this;
        },
        setup: function(data, namespaces) {
          $this = $(this);
          return $this.data('defer-' + eventName, new $.Deferred());
        },
        teardown: function(namespaces) {
          $this = $(this);
          return $this.data('defer-' + eventName, null);
        },
        add: function(handleObj) {
          var Deferred, specialEvent;
          $this = $(this);
          Deferred = $this.data('defer-' + eventName);
          specialEvent = $.event.special[eventName];
          if (!Deferred) {
            specialEvent.setup.call(this);
            return specialEvent.add.apply(this, [handleObj]);
          }
          return Deferred.done(handleObj.handler);
        },
        remove: function(handleObj) {}
      };
      boundHandlers = [];
      $.each(($this.data('events') || {})[eventName] || [], function(i, event) {
        return boundHandlers.push(event.handler);
      });
      $this.unbind(eventName);
      $this.bind(eventName, events.trigger);
      $.fn[eventName] = $.fn[eventName] || events.bind;
      $.event.special[eventName] = $.event.special[eventName] || {
        setup: events.setup,
        teardown: events.teardown,
        add: events.add,
        remove: events.remove
      };
      $.each(boundHandlers, function(i, handler) {
        return $this.bind(eventName, handler);
      });
      return $this;
    };
  };
  $(function() {
    return $('body').createPromiseEvent('html5edit-ready').trigger('html5edit-ready');
  });
}).call(this);
