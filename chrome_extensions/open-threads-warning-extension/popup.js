const box = document.getElementById('block');

chrome.storage.sync.get({ blockMerge: true }, (v) => {
  box.checked = v.blockMerge;
});

box.addEventListener('change', () => {
  chrome.storage.sync.set({ blockMerge: box.checked });
});
