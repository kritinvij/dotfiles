const personal = { name: "Google Chrome", profile: "Default" };

const domain = (...names) =>
  new RegExp(`^https?://([^/]*\\.)?(${names.join("|").replace(/\./g, "\\.")})(/|$|\\?)`);

export default {
  defaultBrowser: {
    name: "Google Chrome",
    profile: "Profile 1",
  },
  handlers: [
    {
      match: [
        domain("hotstar.com", "jiohotstar.com"),
        domain("netflix.com"),
        domain("primevideo.com"),
        domain("airtelxstream.in"),
        /^https?:\/\/(www\.)?amazon\.[a-z.]+\/(gp\/video|Prime-Video)/i,
      ],
      browser: personal,
    },
    // Must stay after the streaming handler: Prime Video links on amazon.* go to Chrome first.
    {
      match: [
        domain(
          "amazon.com", "amazon.in", "amazon.co.uk", "amazon.ca", "amazon.de", "amzn.to", "a.co",
          "flipkart.com", "myntra.com", "ebay.com", "etsy.com", "walmart.com", "target.com",
          "bestbuy.com", "aliexpress.com", "nykaa.com", "meesho.com", "ajio.com"
        ),
      ],
      browser: "Firefox",
    },
  ],
};
