#!/bin/bash
# listen for MQTT messages from boxes
#   1. save state for frontend to visualise
#   2. respond to messages at points

source .env

if [[ -z "${MOSQUITTO_HOST}" ]] || [[ -z "${MOSQUITTO_ROOT_TOPIC}" ]] \
  || [[ -z "${MOSQUITTO_USERNAME}" ]] || [[ -z "${MOSQUITTO_PASSWORD}" ]]; then
  echo "don't have enough information. does .env exist?" >&2 && exit 1
fi

echo "starting to listen…" >&2

while read -u 10 -r message; do
  timestamp=$(date '+%s')
  echo "[${timestamp}] Got MQTT message!" >&2
  date | sed 's+^+  +' >&2
  echo "  mqtt: ${message}" >&2
  topic=$(echo "${message}" | cut -d' ' -f1)
  payload=$(echo "${message}" | cut -d' ' -f2-)
  echo "  topic: ${topic}" >&2
  echo "  payload: ${payload}" >&2
  message_type=$(echo "${topic}" | cut -d'/' -f2)
  echo "  message type: ${message_type}" >&2
  message_target=$(echo "${topic}" | cut -d'/' -f3)
  echo "  message target: ${message_target}" >&2

  ts=$(date '+%s')
  dt=$(date)

  if [[ "${message_type}" == "registration" ]]; then
    # save registrations to folder based on name
    echo "  === REGISTRATION ===" >&2
    name=$(echo "${payload}" | jq -r .name)
    echo "  saving registration to registrations/${name}.json" >&2
    echo "${payload}" \
      | jq --arg ts "${ts}" --arg dt "${dt}" \
      '.ts=$ts | .dt=$dt' \
      > "registrations/${name}.json"
  elif [[ "${message_type}" == "connected" ]]; then
    # save connection to connections folder
    echo "  === CONNECTED ===" >&2
    name=$(echo "${payload}" | jq -r .name)
    echo "  saving connections to connections/${name}_${ts}.json" >&2
    echo "${payload}" \
      | jq --arg ts "${ts}" --arg dt "${dt}" \
      '.ts=$ts | .dt=$dt' \
      > "connections/${name}_${ts}.json"
  elif [[ "${message_type}" == "command" ]] && [[ "${message_target}" == "SERVER" ]]; then
    echo "  === GOT COMMAND TO SERVER ===" >&2
    read process command commandtext from \
      < <(echo $(echo "${payload}" | jq -r '.process, .command, .commandtext, .from'))
    echo "  process: ${process}" >&2
    echo "  command: ${command}" >&2
    echo "  commandtext: ${commandtext}" >&2
    echo "  from: ${from}" >&2
    if [[ "${commandtext}" == "hrtbt" ]]; then
      echo "  == HEARTBEAT ==" >&2
      echo "writing ${ts} to heartbeats/${from}" >&2
      printf "${ts}" > "heartbeats/${from}"
    else
      echo "  == UNKNOWN SUBCOMMAND ==" >&2
      echo "  doing nothing <3" >&2
    fi
  else
    echo "  === UNKNOWN COMMAND ===" >&2
    echo "  doing nothing" >&2
  fi

  linedata=$(
    echo "${message}" \
      | awk -F'/| *' -v timestamp="${timestamp}" \
        '{printf "%s,location=%s,sensor_id=%s %s=%s %s", $2, $3, $4, $5, $6, timestamp}'
  )
done 10< <(mosquitto_sub -R -h "${MOSQUITTO_HOST}" -t "${MOSQUITTO_ROOT_TOPIC}/#" -u "${MOSQUITTO_USERNAME}" -P "${MOSQUITTO_PASSWORD}" -v)
