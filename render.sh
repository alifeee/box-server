#!/bin/bash
# render HTML page from registration/connection/heartbeat information

FILE="index.html"

cat << EOHTML
<!DOCTYPE html>
<head>
<style>
$(cat style.css)
</style>
<script>
$(cat script.js)
</script>
</head>
<body>
<header>
<h1>Boxes</h1>
<p>
  generated at <time data-ts="$(date '+%s')">$(date)</time>
</p>
<p>
  <button id="autorefresh" onclick="disable_autorefresh()">disable autorefresh</button>
  <button id="refresh" onclick='window.location = window.location;'>refresh now</button>
</p>
</header>
<main>
<h2>boxes</h2>
<section id="all-boxes">
EOHTML

for boxfile in registrations/*.json; do
  # registration info
  json=$(cat "${boxfile}" | jq)
  read name friendlyName reg_ts reg_dt < <(echo $(cat "${boxfile}" | jq -r '.name, .friendlyName, .ts, .dt'))

  # connections
  if [[ -f "connections/${name}.log" ]]; then
    data=$(
      tac "connections/${name}.log" \
        | awk -F' ' '{printf "<time data-ts=%s></time> %s\n", $1, $0}'
    )
    connections='<details>
      <summary>last '"$(echo "${data}" | wc -l)"' connections</summary>
      <pre>'"${data}"'</pre>
    </details>'
  else
    connections="no recorded connections"
  fi

  # heartbeats
  if [[ -f "heartbeats/${name}" ]]; then
    ts=$(cat heartbeats/${name})
    heartbeat="<time data-ts='${ts}' data-good=60>${ts}</time>"
  else
    heartbeat="none yet!"
  fi

  # buttons
  if [[ -f "buttons/${name}" ]]; then
    ts=$(cat buttons/${name})
    buttonpress="<time data-ts='${ts}'>${ts}</time>"
  else
    buttonpress="none yet!"
  fi

  # data
  if [[ -f "data/${name}.log" ]]; then
    data=$(
      tac "data/${name}.log" \
        | awk -F' ' '{printf "<time data-ts=%s></time> %s\n", $1, $0}'
    )
    statuses='<details>
      <summary>last '"$(echo "${data}" | wc -l)"' data status reports</summary>
      <pre>'"${data}"'</pre>
    </details>'
  else
    statuses="no recorded status reports"
  fi
  

  # template
cat << EOHTML
  <div id="" class="box">
  <span class="name">${name}</span>
  <h3 class="friendlyName">${friendlyName}</h3>
  <span class="heartbeat">last heartbeat: ${heartbeat}</span>
  <span class="buttonpress">last button: ${buttonpress}</span>

  <div>${statuses}</div>
  
  <details open>
    <summary>registered: <time data-ts=${reg_ts}>${reg_dt}</time></span></summary>
    <pre>${json}</pre>
  </details>

  <div>${connections}</div>
  </div>
EOHTML
done 

cat << EOHTML 
</section>
</main>
</body>
EOHTML

echo "done! :]" >&2
