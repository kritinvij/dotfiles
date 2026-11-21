// Run in the browser console on instagram.com while logged in.
// Everything lives in one function, so pasting it twice never hits "already declared".
// Progress shows in a banner on the page, and the result downloads as a JSON file.
(async () => {
  const username = "<INSERT USER NAME>";
  const headers = { "x-ig-app-id": "936619743392459" };
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  document.getElementById("fb-status")?.remove();
  const banner = document.createElement("div");
  banner.id = "fb-status";
  banner.style.cssText =
    "position:fixed;top:0;left:0;right:0;z-index:999999;padding:10px;background:#000;color:#0f0;font:14px monospace";
  document.body.appendChild(banner);
  const say = (msg) => {
    banner.textContent = msg;
  };

  const getJson = async (url) => {
    const res = await fetch(url, { headers, credentials: "include" });
    if (!res.ok) throw new Error(`${res.status} ${res.statusText} for ${url}`);
    return res.json();
  };

  const getUserId = async () => {
    const cookieId = document.cookie.match(/ds_user_id=(\d+)/)?.[1];
    if (cookieId) return cookieId;
    const json = await getJson(
      `https://www.instagram.com/api/v1/users/web_profile_info/?username=${username}`
    );
    return json.data.user.id;
  };

  const getAll = async (userId, kind) => {
    const out = [];
    let maxId = "";
    do {
      const json = await getJson(
        `https://www.instagram.com/api/v1/friendships/${userId}/${kind}/?count=100` +
          (maxId ? `&max_id=${maxId}` : "")
      );
      out.push(
        ...json.users.map((u) => ({ username: u.username, full_name: u.full_name }))
      );
      maxId = json.next_max_id || "";
      say(`${kind}: ${out.length} fetched...`);
      await sleep(1000 + Math.random() * 1000);
    } while (maxId);
    return out;
  };

  try {
    say("Started. Looking up user id...");
    const userId = await getUserId();

    const followers = await getAll(userId, "followers");
    const followings = await getAll(userId, "following");

    const followerNames = new Set(followers.map((u) => u.username));
    const followingNames = new Set(followings.map((u) => u.username));
    const dontFollowMeBack = followings.filter((u) => !followerNames.has(u.username));
    const iDontFollowBack = followers.filter((u) => !followingNames.has(u.username));

    window.fbResult = { followers, followings, dontFollowMeBack, iDontFollowBack };

    say("Fetched everything. Logging in 5s...");
    await sleep(5000);

    // The iframe console's output doesn't show in the devtools console, so use the page's own.
    const out = console;
    out.info("dontFollowMeBack (you follow, they don't):");
    out.info(dontFollowMeBack);
    out.info("iDontFollowBack (they follow, you don't):");
    out.info(iDontFollowBack);

    say(
      `Done. dontFollowMeBack=${dontFollowMeBack.length} iDontFollowBack=${iDontFollowBack.length}. See the console.`
    );
  } catch (err) {
    say(`Error: ${err.message}`);
  }
})();
