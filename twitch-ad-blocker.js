# https://github.com/uBlockOrigin/uAssets/pull/3517
twitch-videoad.js application/javascript
(function() {
	if ( /(^|\.)twitch\.tv$/.test(document.location.hostname) === false ) { return; }
	var realFetch = window.fetch;
	window.fetch = function(input, init) {
		if ( arguments.length >= 2 && typeof input === 'string' && input.includes('/access_token') ) {
			var url = new URL(arguments[0]);
                        url.searchParams.forEach(function(value, key) {
                            url.searchParams.delete(key);
                        });
			arguments[0] = url.href;
		}
		return realFetch.apply(this, arguments);
	};
})();
