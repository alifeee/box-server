function timeSince(timestamp) {
  var seconds = Math.floor(new Date() - timestamp * 1000) / 1000;

  var interval = seconds / 31536000;

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
    agoEl.innerText = ` (${timeSince(ts)} ago)`;
    time.appendChild(agoEl);

    setInterval(function () {
      agoEl.innerText = ` (${timeSince(ts)} ago)`;
    }, 1000);
  });
});
