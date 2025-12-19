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
  <a id="refresh" href="/">REFRESH</a>
  generated at <time data-ts="$(date '+%s')">$(date)</time>
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
  connections=$(find connections -type f -name "${name}*.json")
  connections_jsons=$(
    while read conn; do
      cat "${conn}" | jq -c
    done <<< $(echo "${connections}")
  )

  # heartbeats
  if [[ -f "heartbeats/${name}" ]]; then
    ts=$(cat heartbeats/${name})
    heartbeat="<time data-ts='${ts}'>${ts}</time>"
  else
    heartbeat="none yet!"
  fi

  # template
cat << EOHTML
  <div id="" class="box">
  <span class="name">${name}</span>
  <h3 class="friendlyName">${friendlyName}</h3>
  <span class="heartbeat">last heartbeat: ${heartbeat}</span>
  
  <details open>
    <summary>registered: <time data-ts=${reg_ts}>${reg_dt}</time></span></summary>
    <pre>${json}</pre>
  </details>

  <details>
    <summary>$(echo "${connections}" | wc -l) connections</summary>
    <pre>${connections_jsons}</pre>
  </details>
  </div>
EOHTML
done 

cat << EOHTML 
</section>
</main>
</body>
EOHTML

echo "done! :]" >&2
