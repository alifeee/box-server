const timer = setTimeout(function () {
  window.location = window.location;
}, 10000);

function disable_autorefresh() {
  clearTimeout(timer);
  document.querySelector("#autorefresh").classList.add("pressed");
}

function secsSince(timestamp) {
  return Math.floor(new Date() - timestamp * 1000) / 1000;
}

function timeSince(timestamp) {
  const seconds = secsSince(timestamp);

  let interval = seconds / 31536000;

  if (interval > 2) {
    return Math.floor(interval) + " years";
  }
  interval = seconds / 2592000;
  if (interval > 2) {
    return Math.floor(interval) + " months";
  }
  interval = seconds / 86400;
  if (interval > 2) {
    return Math.floor(interval) + " days";
  }
  interval = seconds / 3600;
  if (interval > 2) {
    return Math.floor(interval) + " hours";
  }
  interval = seconds / 60;
  if (interval > 2) {
    return Math.floor(interval) + " minutes";
  }
  return Math.floor(seconds) + " seconds";
}

document.addEventListener("DOMContentLoaded", () => {
  // for each time el, add an updating "(40 secs ago)" element
  document.querySelectorAll("time").forEach((time) => {
    const ts = time.dataset["ts"];

    let agoEl = document.createElement("span");
    agoEl.style.color = "lightblue";
    time.appendChild(agoEl);

    function update() {
      agoEl.innerText = ` (${timeSince(ts)} ago)`;
      if (time.dataset["good"]) {
        agoEl.style.color =
          secsSince(ts) < time.dataset["good"] ? "lightgreen" : "lightcoral";
      }
    }

    update();
    setInterval(update, 1000);
  });
});
