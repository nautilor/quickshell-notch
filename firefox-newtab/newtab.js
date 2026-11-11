"use strict";
const $ = (id) => document.getElementById(id);
const DEFAULTS = {
  hue: 265, theme: "auto", h24: true, useTop: false, name: "",
  shortcuts: [
    { title: "GitHub", url: "https://github.com" },
    { title: "YouTube", url: "https://youtube.com" },
    { title: "Reddit", url: "https://reddit.com" },
    { title: "Wikipedia", url: "https://wikipedia.org" },
  ],
};
let S;
try { S = { ...DEFAULTS, ...JSON.parse(localStorage.getItem("ent") || "{}") }; } catch { S = { ...DEFAULTS }; }
const save = () => { try { localStorage.setItem("ent", JSON.stringify(S)); } catch {} };

/* ---------- theme ---------- */
const mq = matchMedia("(prefers-color-scheme: dark)");
function applyTheme() {
  const dark = S.theme === "dark" || (S.theme === "auto" && mq.matches);
  document.documentElement.dataset.theme = dark ? "dark" : "light";
  document.documentElement.style.setProperty("--h", S.hue);
  document.querySelectorAll("#themeSeg button").forEach((b) => b.classList.toggle("on", b.dataset.v === S.theme));
}
mq.addEventListener("change", applyTheme);

/* ---------- clock ---------- */
function tick() {
  const d = new Date();
  $("time").textContent = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: !S.h24 }).replace(/\s?[AP]M$/i, "");
  $("date").textContent = d.toLocaleDateString([], { weekday: "long", day: "numeric", month: "long" });
  const h = d.getHours();
  const part = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
  $("greet").textContent = part + (S.name ? ", " + S.name : "");
}

/* ---------- search ---------- */
$("search").addEventListener("submit", (e) => {
  e.preventDefault();
  const q = $("q").value.trim();
  if (!q) return;
  const looksUrl = /^(https?:\/\/|about:|file:)/i.test(q) || /^[^\s]+\.[a-z]{2,}(\/\S*)?$/i.test(q);
  if (looksUrl) location.href = /^[a-z]+:/i.test(q) ? q : "https://" + q;
  else browser.search.search({ query: q, disposition: "CURRENT_TAB" });
});

/* ---------- shortcuts ---------- */
const RADII = ["50%", "30%", "42% 58% 58% 42% / 50% 42% 58% 50%", "38%", "58% 42% 50% 50% / 42% 58% 42% 58%"];
const normUrl = (u) => (/^[a-z]+:\/\//i.test(u) ? u : "https://" + u);
function tile(item, i, removable) {
  const a = document.createElement("a");
  a.className = "tile"; a.href = item.url;
  const b = document.createElement("div");
  b.className = "badge";
  b.style.setProperty("--r", RADII[i % RADII.length]);
  b.style.setProperty("--c", [`var(--primary-c)`, `var(--secondary-c)`, `var(--tertiary-c)`][i % 3]);
  b.textContent = (item.title || item.url).replace(/^https?:\/\/(www\.)?/, "").charAt(0);
  const n = document.createElement("div");
  n.className = "name"; n.textContent = item.title;
  a.append(b, n);
  if (removable) {
    const x = document.createElement("button");
    x.className = "del"; x.textContent = "×"; x.setAttribute("aria-label", "Remove " + item.title);
    x.addEventListener("click", (e) => { e.preventDefault(); S.shortcuts.splice(i, 1); save(); renderGrid(); });
    a.append(x);
  }
  return a;
}
async function renderGrid() {
  const grid = $("grid"); grid.replaceChildren();
  S.shortcuts.forEach((s, i) => grid.append(tile(s, i, true)));
  if (S.useTop) {
    try {
      const have = new Set(S.shortcuts.map((s) => s.url));
      const top = (await browser.topSites.get({ limit: 12 })).filter((t) => !have.has(t.url));
      top.slice(0, Math.max(0, 12 - S.shortcuts.length)).forEach((t, j) =>
        grid.append(tile({ title: t.title || new URL(t.url).hostname, url: t.url }, S.shortcuts.length + j, false)));
    } catch {}
  }
}

/* ---------- settings sheet ---------- */
const sheet = $("sheet");
const setSwitch = (el, v) => el.setAttribute("aria-checked", String(!!v));
function syncUI() {
  $("hue").value = S.hue; $("name").value = S.name;
  setSwitch($("h24"), S.h24); setSwitch($("useTop"), S.useTop);
}
$("settingsBtn").onclick = () => { syncUI(); sheet.hidden = false; };
$("closeBtn").onclick = () => (sheet.hidden = true);
sheet.addEventListener("click", (e) => { if (e.target === sheet) sheet.hidden = true; });
addEventListener("keydown", (e) => { if (e.key === "Escape") sheet.hidden = true; });
$("hue").oninput = (e) => { S.hue = +e.target.value; save(); applyTheme(); };
$("name").oninput = (e) => { S.name = e.target.value.trim(); save(); tick(); };
$("themeSeg").addEventListener("click", (e) => { const v = e.target.dataset.v; if (v) { S.theme = v; save(); applyTheme(); } });
$("h24").onclick = () => { S.h24 = !S.h24; setSwitch($("h24"), S.h24); save(); tick(); };
$("useTop").onclick = () => { S.useTop = !S.useTop; setSwitch($("useTop"), S.useTop); save(); renderGrid(); };
$("addForm").addEventListener("submit", (e) => {
  e.preventDefault();
  S.shortcuts.push({ title: $("addTitle").value.trim(), url: normUrl($("addUrl").value.trim()) });
  save(); renderGrid(); e.target.reset();
});

applyTheme(); tick(); renderGrid(); setInterval(tick, 1000);
$("q").focus();
