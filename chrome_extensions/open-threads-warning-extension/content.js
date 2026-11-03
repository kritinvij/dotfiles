
(function () {
  'use strict';

  const BANNER_ID = 'open-threads-warning-banner';
  // An open thread shows a "Resolve ..." button. A resolved one shows "Unresolve ...", which this pattern skips.
  function findResolveButtons() {
    return Array.from(document.querySelectorAll('button')).filter((b) => /^\s*resolve\b/i.test(b.textContent));
  }

  // Labels of the merge buttons, including the "Confirm ..." step. Add a label here if GitHub shows another.
  const MERGE_LABEL = /^\s*(confirm\s+)?(merge pull request|squash and merge|rebase and merge|create a merge commit|merge when ready|enable auto-merge|auto-merge|merge|squash|rebase)\s*$/i;
  let openCount = 0;
  // Set from the toolbar popup. Blocking is on until the user turns it off.
  let blockMerge = true;
  const isBlocking = () => blockMerge && openCount > 0;

  chrome.storage.sync.get({ blockMerge: true }, (v) => {
    blockMerge = v.blockMerge;
    markMergeButtons();
  });
  chrome.storage.onChanged.addListener((changes) => {
    if (changes.blockMerge) {
      blockMerge = changes.blockMerge.newValue;
      markMergeButtons();
      if (!blockMerge) hideTip();
    }
  });

  function findMergeButtons() {
    return Array.from(document.querySelectorAll('button')).filter((b) => MERGE_LABEL.test(b.textContent));
  }

  // Dim the merge buttons for looks. The click guard below does the actual blocking.
  function markMergeButtons() {
    findMergeButtons().forEach((b) => {
      if (isBlocking()) {
        b.style.opacity = '0.45';
        b.style.cursor = 'not-allowed';
      } else {
        b.style.opacity = '';
        b.style.cursor = '';
      }
    });
  }

  // Custom tooltip: the native title attribute is small and slow to appear.
  const TIP_ID = 'open-threads-warning-tip';

  function hideTip() {
    const tip = document.getElementById(TIP_ID);
    if (tip) tip.remove();
  }

  function showTip(btn) {
    hideTip();
    const n = openCount;
    const tip = document.createElement('div');
    tip.id = TIP_ID;
    tip.style.cssText = 'position:fixed;z-index:100000;max-width:280px;padding:10px 12px;border-radius:8px;' +
      'background:#1f2328;color:#fff;font:500 13px/1.4 -apple-system,sans-serif;box-shadow:0 6px 20px rgba(0,0,0,.35);' +
      'pointer-events:none;';
    const body = document.createElement('div');
    body.textContent = `Resolve ${n} open thread${n === 1 ? '' : 's'} to merge.`;
    const arrow = document.createElement('div');
    arrow.style.cssText = 'position:absolute;left:50%;bottom:-5px;width:10px;height:10px;background:#1f2328;' +
      'transform:translateX(-50%) rotate(45deg);';
    tip.append(body, arrow);
    document.body.appendChild(tip);
    const r = btn.getBoundingClientRect();
    const t = tip.getBoundingClientRect();
    const left = Math.min(Math.max(8, r.left + r.width / 2 - t.width / 2), window.innerWidth - t.width - 8);
    tip.style.left = `${left}px`;
    tip.style.top = `${Math.max(8, r.top - t.height - 10)}px`;
    // Keep the arrow under the button's center even when the tooltip is nudged sideways.
    arrow.style.left = `${r.left + r.width / 2 - left}px`;
  }

  document.addEventListener('mouseover', (e) => {
    if (!isBlocking() || !(e.target instanceof Element)) return;
    const btn = e.target.closest('button');
    if (btn && MERGE_LABEL.test(btn.textContent)) showTip(btn);
  }, true);

  document.addEventListener('mouseout', (e) => {
    if (!(e.target instanceof Element)) return;
    const btn = e.target.closest('button');
    if (btn && MERGE_LABEL.test(btn.textContent)) hideTip();
  }, true);

  // Capture phase runs before GitHub's handlers, and survives GitHub re-rendering the button.
  document.addEventListener('click', (e) => {
    if (!isBlocking() || !(e.target instanceof Element)) return;
    const btn = e.target.closest('button');
    if (btn && MERGE_LABEL.test(btn.textContent)) {
      e.preventDefault();
      e.stopImmediatePropagation();
    }
  }, true);

  function removeBanner() {
    const old = document.getElementById(BANNER_ID);
    if (old) old.remove();
  }

  function showBanner(open) {
    const n = open.length;
    const old = document.getElementById(BANNER_ID);
    // Skip a rebuild when the count is unchanged, so our own DOM change doesn't retrigger the observer.
    if (old && old.dataset.count === String(n)) return;
    removeBanner();
    const bar = document.createElement('div');
    bar.id = BANNER_ID;
    bar.dataset.count = String(n);
    // Orange bar, white count pill, outlined white button, so each piece stands apart without a yellow tint.
    bar.style.cssText = 'position:sticky;top:0;z-index:99999;padding:5px 16px;font:600 14px -apple-system,sans-serif;' +
      'color:#fff;background:#7a2e0e;' +
      'display:flex;align-items:center;justify-content:center;flex-wrap:wrap;gap:10px;';
    const label = document.createElement('span');
    label.textContent = 'Review the comments before merging:';
    const count = document.createElement('span');
    count.textContent = `${n} unresolved thread${n === 1 ? '' : 's'}`;
    count.style.cssText = 'background:#fff;color:#7a2e0e;font-weight:800;padding:1px 10px;border-radius:999px;';
    bar.append(label, count);
    const a = document.createElement('a');
    a.href = '#';
    a.textContent = 'Jump to the first one';
    a.style.cssText = 'color:#fff;font-weight:600;text-decoration:underline;';
    a.addEventListener('click', (e) => {
      e.preventDefault();
      // Re-query on click: GitHub re-renders threads, which detaches the buttons found earlier.
      const first = findResolveButtons()[0];
      if (first) first.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
    bar.appendChild(a);
    document.body.prepend(bar);
  }

  function check() {
    if (!/^\/[^/]+\/[^/]+\/pull\/\d+/.test(location.pathname)) {
      openCount = 0;
      return removeBanner();
    }
    const open = findResolveButtons();
    openCount = open.length;
    if (open.length > 0) showBanner(open);
    else removeBanner();
    markMergeButtons();
  }

  // GitHub swaps page content without reloads and lazy-loads threads, so re-check on DOM changes.
  let timer = null;
  new MutationObserver(() => {
    clearTimeout(timer);
    timer = setTimeout(check, 500);
  }).observe(document.body, { childList: true, subtree: true });
  check();
})();
