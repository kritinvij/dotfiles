# Chrome Web Store listing

## Name

PR Open Threads Guard

## Summary (max 132 characters)

Warns you about unresolved review threads on a GitHub pull request and blocks merging until they are resolved.

## Detailed description

PR Open Threads Guard stops you from merging a GitHub pull request while review comments are still open.

When a pull request has unresolved review threads, the extension:

- Shows a banner at the top of the page with the number of open threads.
- Adds a "Jump to the first one" link that scrolls to the first unresolved thread.
- Dims the merge buttons and blocks clicks on them.
- Shows a tooltip on the merge button that says how many threads to resolve.

The banner and the block disappear when the last thread is resolved.

Click the toolbar icon to turn the merge block off. The banner keeps showing either way.

The extension reads the page you are already viewing. It makes no network requests, needs no GitHub token, and stores one setting: whether to block the merge buttons.

The block works in your browser only. It does not change GitHub branch protection settings.

## Category

Developer Tools

## Single purpose

Warn about unresolved review threads on GitHub pull requests and block the merge buttons until they are resolved.

## Permission justification

Host access to `https://github.com/*`: the extension runs a content script on GitHub pages. It reads the page to count "Resolve conversation" buttons, shows the banner, and blocks the merge buttons. GitHub changes pages without full reloads, so the script loads on all github.com pages and acts only on pull request URLs.

`storage`: saves one on/off setting, whether to block the merge buttons, so the toolbar popup choice persists.

The extension requests no other permissions.

## Visibility

Public.

## Privacy practices

- Data collected: none. The saved on/off setting stays in the browser.
- Remote code: none. All code ships in the package.
- Data is not sold, transferred, or used for unrelated purposes.

## Screenshot checklist (1280x800)

1. A pull request page with the banner showing open threads.
2. The merge button with the tooltip visible.
