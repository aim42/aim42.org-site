---
title: Search
layout: aim42-page
permalink: /search/
lede: Find patterns, glossary terms and pages.
---

<form class="search-page__form" action="{{ '/search/' | relative_url }}" method="get" role="search">
  <label class="visually-hidden" for="search-page-input">Search patterns and pages</label>
  <input id="search-page-input" class="search-page__input" type="search" name="q" autocomplete="off" spellcheck="false" />
  <button class="search-page__button" type="submit">Search</button>
</form>

<p id="search-page-status" class="search-page__status" aria-live="polite"></p>

<noscript><p>Search needs JavaScript. Browse the <a href="{{ '/patterns/' | relative_url }}">patterns index</a> instead.</p></noscript>

<ul id="search-page-results" class="search-results search-results--page"></ul>
