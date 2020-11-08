// https://github.com/uBlockOrigin/uAssets/pull/3517
// twitch-videoad.js application/javascript
// (function() {
// 	if ( /(^|\.)twitch\.tv$/.test(document.location.hostname) === false ) { return; }
// 	var realFetch = window.fetch;
// 	window.fetch = function(input, init) {
// 		if ( arguments.length >= 2 && typeof input === 'string' && input.includes('/access_token') ) {
// 			var url = new URL(arguments[0]);
//                         url.searchParams.forEach(function(value, key) {
//                             url.searchParams.delete(key);
//                         });
// 			arguments[0] = url.href;
// 		}
// 		return realFetch.apply(this, arguments);
// 	};
// })();

/// twitch-videoad.js
// const origFetch = window.fetch;
// window.fetch = (url, init, ...args) => {
// 	if (typeof url === "string") {
// 		if (url.includes("/access_token")) {
// 			url = url.replace("player_type=site", "player_type=facebook");
// 		} else if (
// 			url.includes("/gql") &&
// 			init &&
// 			typeof init.body === "string" &&
// 			init.body.includes("PlaybackAccessToken")
// 		) {
// 			const newBody = JSON.parse(init.body);
// 			newBody.variables.playerType = "facebook";
// 			init.body = JSON.stringify(newBody);
// 		}
// 	}
// 	return origFetch(url, init, ...args);
// };

/// twitch-videoad.js
const origFetch = window.fetch;
window.fetch = (url, init, ...args) => {
	if (typeof url === "string") {
		if (url.includes("/access_token")) {
			// url = url.replace("player_type=site", "player_type=site");
		} else if (
			url.includes("/gql") &&
			init &&
			typeof init.body === "string" &&
			init.body.includes("PlaybackAccessToken")
		) {
			// const newBody = JSON.parse(init.body);
			// newBody.variables.playerType = "site";
			// init.body = JSON.stringify(newBody);
		}
	}
	return origFetch(url, init, ...args);
};
