#!/bin/bash
# listen for MQTT messages from boxes
#   1. save state for frontend to visualise
#   2. respond to messages at points

source .env

if [[ -z "${MOSQUITTO_HOST}" ]] || [[ -z "${MOSQUITTO_ROOT_TOPIC}" ]] \
  || [[ -z "${MOSQUITTO_USERNAME}" ]] || [[ -z "${MOSQUITTO_PASSWORD}" ]] \
  || [[ -z "${BOX_PARTNER_1}" ]] || [[ -z "${BOX_PARTNER_2}" ]]; then
  echo "don't have enough information. does .env exist?" >&2 && exit 1
fi

IDLE_TIME=300 # wait this long until considering other box as missing
BUTTON_TIME=15 # wait this long until cancelling button press
LAST_BUTTON_PRESS_TS_BOX1=0
LAST_BUTTON_PRESS_TS_BOX2=0

date >&2
echo "starting to listen…" >&2

# pub command/CLB-f8waj '{"process":"pixels","command":"setrandomcolour", "from": "PC"}'
pub() {
  mosquitto_pub \
    -h "${MOSQUITTO_HOST}" -u "${MOSQUITTO_USERNAME}" -P "${MOSQUITTO_PASSWORD}" \
    -t "${MOSQUITTO_ROOT_TOPIC}/${1}" -m "${2}"
}

# colour state for "waiting for other box to come online"
waitingforother() {
  name="${1}"
  pub "command/${name}" '{"process":"pixels","command":"setnamedcolour","colourname":"purple","store":"buttoncolours","id":"setcolour"}'
  pub "command/${name}" '{"process":"pixels","command":"pattern","pattern":"mask","colourmask":"GKGKGKGKGKGK"}'
}

# colour state for "heartbeat"
beat_heart() {
  name="${1}"
  pub "command/${name}" '{"process":"pixels","command":"setnamedcolour","colourname":"red","steps":10,"from":"SERVER"}'
  pub "command/${name}" '{"process":"pixels","command":"setnamedcolour","colourname":"black","steps":12,"from":"SERVER"}'
}

# colour state for "me pressed"
me_pressed() {
  name="${1}"
  pub "command/${name}" '{"process":"pixels","command":"setnamedcolour","colourname":"purple","steps":10,"from":"SERVER"}'
}
other_pressed() {
  name="${1}"
  pub "command/${name}" '{"process":"pixels","command":"setnamedcolour","colourname":"orange","steps":10,"from":"SERVER"}'
}
both_pressed() {
  name="${1}"
  pub "command/${name}" '{"process":"pixels","command":"setnamedcolour","colourname":"red","steps":10,"from":"SERVER"}'
}

while read -u 10 -r message; do
  timestamp=$(date '+%s')
  echo ""
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
    echo "  adding button trigger" >&2
    otherbox="CLB-iuwjfiuwjf"
    waitingforother "${name}"
  elif [[ "${message_type}" == "connected" ]]; then
    # save last 10 connections
    echo "  === CONNECTED ===" >&2
    name=$(echo "${payload}" | jq -r .name)
    echo "  saving connections to connections/${name}.log" >&2
    echo "${ts} ${payload}" >> "connections/${name}.log"
    cat "connections/${name}.log" | tail -n10 > "/tmp/28f2w8gjj2w8i.log"
    cat "/tmp/28f2w8gjj2w8i.log" > "connections/${name}.log"
  elif [[ "${message_type}" == "data" ]]; then
    # save last 10 data requests
    echo "  === DATA RESPONSE ===" >&2
    name="${message_target}"
    echo "  appending data response to data/${name}.log" >&2
    echo "${ts} ${payload}" >> "data/${name}.log"
    cat "data/${name}.log" | tail -n10 > /tmp/28288t28ju.log
    cat /tmp/28288t28ju.log > "data/${name}.log"
  elif [[ "${message_type}" == "command" ]] && [[ "${message_target}" == "SERVER" ]]; then
    echo "  === GOT COMMAND TO SERVER ===" >&2
    read process command commandtext from \
      < <(echo $(echo "${payload}" | jq -r '.process, .command, .commandtext, .from'))
    echo "  process: ${process}" >&2
    echo "  command: ${command}" >&2
    echo "  commandtext: ${commandtext}" >&2
    echo "  from: ${from}" >&2

    # check if this is box 1 or 2
    # (this could be made generic to check pairs of boxes)
    if [[ "${from}" == "${BOX_PARTNER_1}" ]]; then
      this_box="${BOX_PARTNER_1}"
      that_box="${BOX_PARTNER_2}"
    elif [[ "${from}" == "${BOX_PARTNER_2}" ]]; then
      this_box="${BOX_PARTNER_2}"
      that_box="${BOX_PARTNER_1}"
    else
      echo "  === not a box we want! short circuiting !!! ===" && continue
    fi
    echo "  this box: ${this_box}" >&2
    echo "  other box: ${that_box}" >&2

    if [[ "${commandtext}" == "hrtbt" ]]; then
      echo "  == HEARTBEAT ==" >&2
      # save to file
      echo "  writing ${ts} to heartbeats/${from}" >&2
      printf "${ts}" > "heartbeats/${from}"
      # check last heartbeat time of other device
      if [[ -f "heartbeats/${that_box}" ]]; then
        that_box_last_hb_ts=$(cat "heartbeats/${that_box}")
      else
        that_box_last_hb_ts=0
      fi
      if [[ $(( $ts - $that_box_last_hb_ts )) -gt "${IDLE_TIME}" ]]; then
        # box has gone missing!
        echo "  other box last ts was $that_box_last_hb_ts ($(( $ts - $that_box_last_hb_ts )) s ago)" >&2
        echo "  sending reset" >&2
        waitingforother "${this_box}"
      else
        # beat heart of other box
        echo "  beating heart of other box" >&2
        beat_heart "${that_box}"
      fi
    elif [[ "${commandtext}" == "btn" ]]; then
      echo "  == BUTTON ==" >&2
      # save to file
      echo "  writing ${ts} to buttons/${from}" >&2
      printf "${ts}" > "buttons/${from}"
      if [[ -f "buttons/${that_box}" ]]; then
        that_box_last_btn_ts=$(cat "buttons/${that_box}")
      else
        that_box_last_btn_ts=0
      fi
      if [[ $(( $ts - $that_box_last_btn_ts )) -gt "${BUTTON_TIME}" ]]; then
        # other button has not been pressed in the last N seconds
        echo "  other box has not been pressed recently!" >&2
        echo "  last ts was ${that_box_last_btn_ts}!" >&2
        me_pressed "${this_box}"
        other_pressed "${that_box}"
      else
        # other button has been pressed recently !!!
        echo "  other box has been pressed! coalescence" >&2
        both_pressed "${this_box}"
        both_pressed "${that_box}"
      fi
    else
      echo "  == UNKNOWN SUBCOMMAND ==" >&2
      echo "  doing nothing <3" >&2
    fi
  else
    echo "  === UNKNOWN COMMAND ===" >&2
    echo "  doing nothing" >&2
  fi
done 10< <(
  mosquitto_sub -R -v -h "${MOSQUITTO_HOST}" \
    -u "${MOSQUITTO_USERNAME}" -P "${MOSQUITTO_PASSWORD}" \
    -t "${MOSQUITTO_ROOT_TOPIC}/command/SERVER" \
    -t "${MOSQUITTO_ROOT_TOPIC}/data/#" \
    -t "${MOSQUITTO_ROOT_TOPIC}/registration/#" \
    -t "${MOSQUITTO_ROOT_TOPIC}/connected/#"
  )
