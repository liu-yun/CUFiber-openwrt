#!/bin/bash
# Copyright (C) 2016 Yun Liu
LOGFILE="/tmp/cubatch.log"
UA="Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) CriOS/60.0.3112.89 Mobile/15A5370a Safari/602.1"
IF_NUM=10

log() {
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "${LOGFILE}" 2>&1
}

load_users() {
  USERS_FILE="$(cd $(dirname $0); pwd)/users.csv"
  usernames=()
  passwords=()
  while IFS=",", read username password; do
    usernames+=(${username})
    passwords+=(${password})
  done < "${USERS_FILE}"
}

get_ip() {
  ip_retry=0
  ip=$(ip -4 addr show $1 | grep -oE "172\.16\.[0-9]{1,3}\.[0-9]{1,3}" | awk 'NR==1')
  until [[ -n "${ip}" ]]; do
    sleep 5
    log "Retry for $1 IP."
    ((ip_retry += 1))
    ip=$(ip -4 addr show $1 | grep -oE "172\.16\.[0-9]{1,3}\.[0-9]{1,3}" | awk 'NR==1')
    if [[ "${ip_retry}" -gt 5 ]]; then
      log "ifup $2"
      ifup "$2"
      ip_retry=0
    fi
  done
  log "IP: ${ip}"
  cookie=$(curl "http://114.247.41.52:808" --head -s --connect-timeout 10 | grep "Set-Cookie" | cut -c13-55)
}

login() {
  response=$(curl "http://114.247.41.52:808/protalAction!portalAuth.action?" \
    -H "Cookie: ${cookie}" \
    -H "Origin: http://114.247.41.52:808" \
    -H "Accept-Encoding: gzip, deflate" \
    -H "Accept-Language: zh-CN,zh;q=1" \
    -H "User-Agent: ${UA}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Accept: application/json, text/javascript, */*" \
    -H "Referer: http://114.247.41.52:808/protalAction!index.action?wlanuserip=${ip}&basip=61.148.2.182" \
    -H "X-Requested-With: XMLHttpRequest" \
    -H "Connection: keep-alive" \
    --data "wlanuserip=${ip}&localIp=&basip=61.148.2.182&lpsUserName=${usernames[$1]}&lpsPwd=${passwords[$1]}" \
    --connect-timeout 5 -s)
}

all() {
  interfaces=("eth0.2")
  devices=("wan")
  for j in $(seq 1 "${IF_NUM}"); do
    interfaces+=("macvlan${j}")
    devices+=("vwan${j}")
    done

  load_users
  current=0

  for i in $(seq 0 "${IF_NUM}"); do
    log "-----------------------------------"
    log "Initiating ${interfaces[$i]}."
    get_ip "${interfaces[${i}]}" "${devices[${i}]}"

    retry=0
    success=
    while [[ -z "${success}" && "${retry}" -lt 5 && "${current}" -lt "${#usernames[@]}" ]]; do
      ((retry += 1))
      login ${current}
      success=$(echo ${response} | grep -oE 'login success|connection created')
      created=$(echo ${response} | grep -oE 'connection created')
      result=$(echo ${response} | grep -oE 'login refused|login on error|logout refused|login success|connection created|"msg":""')
      log "Result: ${usernames[${current}]} ${result}"
      if [[ -z "${result}" ]]; then
        log "${response}" # no matching result
      fi
      if [[ -z "${success}" ]]; then
        ((current += 1)) # current user failed
      fi
      if [[ -n "${created}" ]]; then
        ((current -= 1)) # current interface already logged-in
      fi
    done
    ((current += 1))
  done
  log "Done."
}

case $1 in
  *)
    all
    ;;
esac
exit
