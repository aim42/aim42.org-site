// Site search. Spec: docs/superpowers/specs/2026-10-07-phase3a-search-design.md
// Lunr and /assets/search.json load on first use. The popup (every page) and
// the results page (/search/) share loading, querying and rendering.
(function () {
  "use strict";

  var dialog = document.getElementById("search-dialog");
  if (!dialog) return;

  var LUNR_SRC = dialog.getAttribute("data-lunr");
  var INDEX_SRC = dialog.getAttribute("data-index");
  var RESULTS_URL = dialog.getAttribute("data-results");
  var MIN_CHARS = 2;
  var POPUP_LIMIT = 8;
  var DEBOUNCE_MS = 100;
  var engine = null;

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      var script = document.createElement("script");
      script.src = src;
      script.onload = resolve;
      script.onerror = function () { reject(new Error(src + " did not load")); };
      document.head.appendChild(script);
    });
  }

  // Resolves to {index, docs}; docs maps a URL to its search document.
  function loadEngine() {
    if (!engine) {
      engine = Promise.all([
        window.lunr ? Promise.resolve() : loadScript(LUNR_SRC),
        fetch(INDEX_SRC).then(function (response) {
          if (!response.ok) throw new Error(INDEX_SRC + ": HTTP " + response.status);
          return response.json();
        })
      ]).then(function (loaded) {
        var docs = {};
        var index = window.lunr(function () {
          this.ref("url");
          this.field("title", { boost: 10 });
          this.field("context", { boost: 4 });
          this.field("body");
          loaded[1].forEach(function (doc) {
            docs[doc.url] = doc;
            this.add(doc);
          }, this);
        });
        return { index: index, docs: docs };
      }).catch(function (error) {
        engine = null; // the next keystroke tries again
        throw error;
      });
    }
    return engine;
  }

  // Lower-case words of letters and digits only, so Lunr's query syntax
  // (":", "*", "~", "^", "+") never reaches the index.
  function words(query) {
    return query.toLowerCase().split(/\s+/).map(function (word) {
      return word.replace(/[^\p{L}\p{N}]/gu, "");
    }).filter(Boolean);
  }

  function longEnough(query) {
    return words(query).join("").length >= MIN_CHARS;
  }

  // Each word matches as typed (stemmed) and as a prefix while it is still
  // being typed, with equal weight (a lower prefix weight let a stemmed body
  // word, "strange", outrank a title prefix, "Strangler"); documents matching
  // more words rank higher.
  function find(loaded, query) {
    var terms = words(query);
    if (!terms.length) return [];
    return loaded.index.query(function (q) {
      terms.forEach(function (term) {
        q.term(term);
        q.term(term, { usePipeline: false, wildcard: window.lunr.Query.wildcard.TRAILING });
      });
    }).map(function (hit) { return loaded.docs[hit.ref]; });
  }

  function escapeRegExp(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  // Appends text to parent, wrapping each occurrence of a query word in <mark>.
  function appendHighlighted(parent, text, terms) {
    if (!terms.length) {
      parent.appendChild(document.createTextNode(text));
      return;
    }
    var pattern = new RegExp("(" + terms.map(escapeRegExp).join("|") + ")", "gi");
    var last = 0;
    var match;
    while ((match = pattern.exec(text))) {
      parent.appendChild(document.createTextNode(text.slice(last, match.index)));
      var mark = document.createElement("mark");
      mark.textContent = match[0];
      parent.appendChild(mark);
      last = pattern.lastIndex;
    }
    parent.appendChild(document.createTextNode(text.slice(last)));
  }

  // One result: a link with title, label and context line. With an id it is
  // a listbox option (popup); without, a plain list item (results page).
  function resultItem(doc, terms, id) {
    var item = document.createElement("li");
    item.className = "search-result";
    var link = document.createElement("a");
    link.className = "search-result__link";
    link.href = doc.url;
    if (id) {
      item.id = id;
      item.setAttribute("role", "option");
      item.setAttribute("aria-selected", "false");
      link.tabIndex = -1;
    }
    var title = document.createElement("span");
    title.className = "search-result__title";
    appendHighlighted(title, doc.title, terms);
    var label = document.createElement("span");
    label.className = "search-result__label";
    label.textContent = doc.label;
    var context = document.createElement("span");
    context.className = "search-result__context";
    appendHighlighted(context, doc.context, terms);
    link.append(title, label, context);
    item.appendChild(link);
    return item;
  }

  function quoted(query) {
    return "“" + query.trim() + "”";
  }

  function countText(count) {
    return count === 1 ? "1 result" : count + " results";
  }

  function resultsHref(query) {
    return RESULTS_URL + "?q=" + encodeURIComponent(query.trim());
  }

  function unavailable(status) {
    return function (error) {
      console.error("Search is unavailable:", error);
      status.textContent = "Search is unavailable right now.";
    };
  }

  function isTyping(target) {
    return Boolean(target && target.closest && target.closest("input, textarea, select, [contenteditable=''], [contenteditable='true']"));
  }

  // ---- Popup -------------------------------------------------------------

  var input = document.getElementById("search-dialog-input");
  var list = document.getElementById("search-dialog-results");
  var status = dialog.querySelector(".search-dialog__status");
  var none = dialog.querySelector(".search-dialog__none");
  var all = dialog.querySelector(".search-dialog__all");
  var opener = null;
  var selected = -1;
  var timer = null;

  function popupOptions() {
    return list.querySelectorAll("[role=option]");
  }

  function select(position) {
    var options = popupOptions();
    if (!options.length) return;
    selected = (position + options.length) % options.length;
    options.forEach(function (option, n) {
      option.setAttribute("aria-selected", n === selected ? "true" : "false");
    });
    input.setAttribute("aria-activedescendant", options[selected].id);
    options[selected].scrollIntoView({ block: "nearest" });
  }

  function renderPopup() {
    var query = input.value;
    selected = -1;
    input.removeAttribute("aria-activedescendant");
    input.setAttribute("aria-expanded", "false");
    list.replaceChildren();
    none.hidden = true;
    all.hidden = true;
    if (!longEnough(query)) {
      status.textContent = "";
      return;
    }
    loadEngine().then(function (loaded) {
      if (query !== input.value) return; // a newer keystroke renders instead
      var terms = words(query);
      var hits = find(loaded, query);
      hits.slice(0, POPUP_LIMIT).forEach(function (doc, n) {
        list.appendChild(resultItem(doc, terms, "search-option-" + n));
      });
      input.setAttribute("aria-expanded", hits.length ? "true" : "false");
      if (!hits.length) {
        status.textContent = "No matches for " + quoted(query) + ".";
        none.hidden = false;
        return;
      }
      status.textContent = countText(hits.length);
      var link = all.querySelector("a");
      link.href = resultsHref(query);
      link.textContent = "Show all " + countText(hits.length);
      all.hidden = false;
    }, unavailable(status));
  }

  function openPopup() {
    if (dialog.open) return;
    opener = document.activeElement;
    dialog.showModal();
    input.select();
    loadEngine().catch(function () {}); // warm up; errors show when typing
    if (input.value) renderPopup();
  }

  dialog.addEventListener("close", function () {
    if (opener && opener.focus) opener.focus();
  });

  // A click on the backdrop closes the popup.
  dialog.addEventListener("click", function (event) {
    if (event.target === dialog) dialog.close();
  });

  input.addEventListener("input", function () {
    clearTimeout(timer);
    timer = setTimeout(renderPopup, DEBOUNCE_MS);
  });

  input.addEventListener("keydown", function (event) {
    var options = popupOptions();
    if (event.key === "Enter") {
      event.preventDefault();
      if (!input.value.trim()) return;
      if (event.metaKey || event.ctrlKey || !options.length) {
        window.location.href = resultsHref(input.value);
        return;
      }
      window.location.href = options[selected >= 0 ? selected : 0].querySelector("a").href;
      return;
    }
    if (!options.length) return;
    var forward = event.key === "ArrowDown" || (event.key === "Tab" && !event.shiftKey);
    var backward = event.key === "ArrowUp" || (event.key === "Tab" && event.shiftKey);
    if (!forward && !backward) return;
    event.preventDefault();
    if (selected < 0) select(forward ? 0 : options.length - 1);
    else select(selected + (forward ? 1 : -1));
  });

  document.addEventListener("keydown", function (event) {
    if (dialog.open || isTyping(event.target)) return;
    var slash = event.key === "/" && !event.metaKey && !event.ctrlKey && !event.altKey;
    var commandK = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k";
    if (!slash && !commandK) return;
    event.preventDefault();
    openPopup();
  });

  document.querySelectorAll("[data-search-open]").forEach(function (trigger) {
    trigger.addEventListener("click", function (event) {
      event.preventDefault();
      openPopup();
    });
  });

  // ---- Results page ------------------------------------------------------

  var pageInput = document.getElementById("search-page-input");
  if (!pageInput) return;
  var pageList = document.getElementById("search-page-results");
  var pageStatus = document.getElementById("search-page-status");
  var pageTimer = null;

  function renderPage() {
    var query = pageInput.value;
    pageList.replaceChildren();
    if (!longEnough(query)) {
      pageStatus.textContent = "Type at least " + MIN_CHARS + " characters.";
      return;
    }
    loadEngine().then(function (loaded) {
      if (query !== pageInput.value) return;
      var terms = words(query);
      var hits = find(loaded, query);
      hits.forEach(function (doc) { pageList.appendChild(resultItem(doc, terms, null)); });
      pageStatus.textContent = hits.length
        ? countText(hits.length) + " for " + quoted(query) + "."
        : "No matches for " + quoted(query) + ".";
    }, unavailable(pageStatus));
  }

  pageInput.value = new URLSearchParams(window.location.search).get("q") || "";
  renderPage();
  pageInput.addEventListener("input", function () {
    clearTimeout(pageTimer);
    pageTimer = setTimeout(function () {
      var query = pageInput.value.trim();
      history.replaceState(null, "", RESULTS_URL + (query ? "?q=" + encodeURIComponent(query) : ""));
      renderPage();
    }, DEBOUNCE_MS);
  });
})();
