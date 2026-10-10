// Navigation toggle for the aim42 header. Ported and trimmed from
// quality.arc42.org (src/scripts/site/navigation.js): the toggle and its
// target get the `active` class, aria-expanded follows; Esc and clicks
// outside the header close it.
(function () {
  var toggles = Array.prototype.slice.call(document.querySelectorAll('.nav-toggle'));

  function setOpen(toggle, open) {
    var target = document.querySelector(toggle.getAttribute('data-target'));
    if (!target) return;
    toggle.classList.toggle('active', open);
    target.classList.toggle('active', open);
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  }

  toggles.forEach(function (toggle) {
    toggle.addEventListener('click', function (event) {
      event.preventDefault();
      setOpen(toggle, !toggle.classList.contains('active'));
    });
  });

  document.addEventListener('keydown', function (event) {
    if (event.key !== 'Escape') return;
    toggles.forEach(function (toggle) {
      if (!toggle.classList.contains('active')) return;
      setOpen(toggle, false);
      toggle.focus();
    });
  });

  document.addEventListener('click', function (event) {
    if (event.target.closest('.site-header')) return;
    toggles.forEach(function (toggle) { setOpen(toggle, false); });
  });
})();
