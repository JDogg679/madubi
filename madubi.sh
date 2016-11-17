#!/bin/bash
#### Description      : Menu driven pacman's mirrorlist updater.
#### Written by       : Sotirios Roussis (aka. xtonousou) - xtonousou@gmail.com on 11-2016
#### Name:            : madubi that means mirror in Hausa

# DEBUG=1 to skip intro, checking functions and traps
DEBUG=0

# colors
GRN="\033[1;32m"
RED="\033[1;31m"
ORNG="\033[1;33m"
STRD="\e[1;0m"

# pacman's mirrorlist files
PAC_LIST_NEW="/etc/pacman.d/mirrorlist.pacnew"
PAC_LIST_OLD="/etc/pacman.d/mirrorlist.old"
PAC_LIST_TMP="/etc/pacman.d/mirrorlist.tmp"
PAC_LIST_="/etc/pacman.d/mirrorlist"

# checkers
MAIN_MENU_CHECK="1"
EXTRA_MENU_CHECK="0"

# default values
AUTHOR="Sotirios Roussis"
AUTHOR_NICKNAME="xtonousou"
GMAIL="${AUTHOR_NICKNAME}@gmail.com"
GITHUB="https://github.com/${AUTHOR_NICKNAME}"
VERSION="1.2"
GOOGLE_DNS="8.8.8.8"
ARCH_MIRRORLIST="https://www.archlinux.org/mirrorlist/"
COUNTRY_LIST="${ARCH_MIRRORLIST}?country="
COUNTRY_IPV4_PART="&protocol=http&ip_version=4"
COUNTRY_IPV6_PART="&protocol=http&ip_version=6"
IPV4_LIST="${ARCH_MIRRORLIST}?ip_version=4"
IPV6_LIST="${ARCH_MIRRORLIST}?ip_version=6"
MIRRORS="5"

function check_permissions() {
  
  if [[ "$(id -u)" -ne "0" ]]; then
     echo -e "${RED}error: ${STRD}you cannot perform this operation unless you are root."
     exit 1
  fi
}

function check_internet_connection() {
  
  if ! ping -c 1 "${GOOGLE_DNS}" -W 1 > /dev/null 2>&1; then
    echo -e "${RED}error: ${STRD}No internet connection."
    exit 1
  fi
}

function check_bash_version() {
  
  if bash --version | grep -Eo "4.[0-9].[0-9][0-9]\([0-9]\)" | grep "^[0-3]"; then
    echo -e "${RED}error: ${STRD}insufficient bash version. You must have bash with version 4 or later."
    exit 1
  fi
}

function check_pacman() {
  
  if ! hash pacman 2> /dev/null; then
    echo -e "${RED}Error${STRD}. Package manager is not ${ORNG}pacman${STRD}."
    exit 1
  fi
}

function check_rankmirrors() {
  
  if ! hash rankmirrors 2> /dev/null; then
    echo -e "${RED}Error${STRD}. ${GRN}rankmirrors${STRD} command not found."
    exit 1
  fi
}

function make_backup() {
  
  if [[ ! -f "${PAC_LIST_OLD}" ]]; then
    start_spinner "A backup has been created ${GRN}${PAC_LIST_OLD}${STRD}"
    sleep 2
    cp "${PAC_LIST_}" "${PAC_LIST_OLD}"
    stop_spinner $?
  fi
}

function reset_main() {
  
  main_menu
  read_main_options
}

function reset_ipvx() {
  
  ipvx_menu
  read_extra_options
}

function reset_ipvx_two() {
  
  ipvx_menu
  read_extra_options_two
}

function reset_ipvx_three() {
  
  ipvx_menu
  read_extra_options_three
}

function clear_line() {
  
  printf "\r\033[K"
}

function spinner() {
  
  # $1 start/stop
  #
  # on start: $2 display message
  # on stop : $2 process exit status
  #           $3 spinner function pid (supplied from stop_spinner)
  
  local STEP
  local SPINNER_PARTS
  local DELAY

  case $1 in
    start)
      # calculate the column where spinner and status msg will be displayed
      let COLUMN=$(tput cols)-${#2}-8
      # display message and position the cursor in $COLUMN column
      echo -ne "${2}"
      printf "%${COLUMN}s"

      # start spinner
      STEP=1
      SPINNER_PARTS='\|/-'
      DELAY=${SPINNER_DELAY:-0.15}

      while :
      do
        printf "\b%s" "${SPINNER_PARTS:STEP++%${#SPINNER_PARTS}:1}"
        sleep "${DELAY}"
      done
    ;;
    stop)
      kill "$3" > /dev/null 2>&1
    ;;
    *)
      echo "Invalid argument!"
      exit 1
    ;;
  esac
}

function start_spinner {
  
  # $1 : msg to display
  spinner "start" "${1}" &
  # set global spinner pid
  SPINNER_ID=$!
  disown
}

function stop_spinner {
  
  # $1 : command exit status
  spinner "stop" "$1" "${SPINNER_ID}"
  unset SPINNER_ID
}

function mr_proper() {
  
  rm -f "${PAC_LIST_NEW}"
  rm -f "${PAC_LIST_TMP}"
  rm -rf /tmp/madubi
}

function exit_script() {
  
  clear
  start_spinner "Cleaning temp files..."
  sleep 2
  mr_proper
  stop_spinner $?
  clear_line
  exit 0
}

function trap_handler() {
  
  local YN
  
  echo
  YN=""
	while [[ ! ${YN} =~ ^[YyNn]$ ]]; do
		echo -ne "Exit? [y/n] "
    read -r YN
	done

	if [ "${YN}" = "Y" ]; then
		YN="y"
	elif [ "${YN}" = "N" ]; then
		YN="n"
	fi
  
	if [ ${YN} = "y" ]; then
    exit_script
  else
		reset_main
  fi
}

function intro() {
    
  clear
  echo -e "${ORNG}"   "                    _       _     _ "
  sleep .1 && echo -e "                    | |     | |   (_)"
  sleep .1 && echo -e " _ __ ___   __ _  __| |_   _| |__  _   ${STRD}Author .: ${RED}${AUTHOR}${ORNG}"
  sleep .1 && echo -e "| '_ \` _ \ / _\` |/ _\` | | | | '_ \| |  ${STRD}Mail ...: ${RED}${GMAIL}${ORNG}"
  sleep .1 && echo -e "| | | | | | (_| | (_| | |_| | |_) | |  ${STRD}Github .: ${RED}${GITHUB}${ORNG}"
  sleep .1 && echo -e "|_| |_| |_|\__,_|\__,_|\__,_|_.__/|_|  ${STRD}Version : ${RED}${VERSION}" "${STRD}"
  sleep 1.2
}

function main_menu() {
  
  clear
  echo    "                 ┌───────────┐"
  echo -e "┌────────────────┤ ${ORNG}Main Menu${STRD} ├─────────────────┐"
  echo    "│                └───────────┘                 │"
  echo -e "│ ${GRN}1${STRD})  Download new mirrorlist                  │"
  echo -e "│ ${GRN}2${STRD})  Download and rank new mirrorlist         │"
  echo -e "│ ${GRN}3${STRD})  Rank new mirrorlist                      │"
  echo -e "│ ${GRN}4${STRD})  Rank new mirrorlist (Country based)      │"
  echo -e "│ ${GRN}5${STRD})  Rank existing mirrorlist                 │"
  echo -e "│ ${GRN}6${STRD})  Rank existing mirrorlist (Country based) │"
  echo -e "│ ${GRN}7${STRD})  Exit                                     │"
  echo    "└──────────────────────────────────────────────┘"
}

function ipvx_menu() {
  
  clear
  echo    "   ┌────────────────┐"
  echo -e "┌──┤ ${ORNG}Selection Menu${STRD} ├──┐"
  echo    "│  └────────────────┘  │"
  echo -e "│ ${GRN}1${STRD})  IPv4 mirrorlist  │"
  echo -e "│ ${GRN}2${STRD})  IPv6 mirrorlist  │"
  echo -e "│ ${GRN}3${STRD})  Return           │"
  echo -e "│ ${GRN}4${STRD})  Exit             │"
  echo    "└──────────────────────┘"
}

function read_main_options() {

  local CHOICE
  
  MAIN_MENU_CHECK="1"
  EXTRA_MENU_CHECK="0"
	read -p "Enter choice [1-7] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) ipvx_menu; read_extra_options ;;
		2) ipvx_menu; read_extra_options_two ;;
		3) make_backup; check_internet_connection; rank_new ;;
		4) ipvx_menu; read_extra_options_three ;;
		5) make_backup; check_internet_connection; rank_existing ;;
		6) make_backup; check_internet_connection; rank_existing_country ;;
		7) exit_script ;;
		*) reset_main ;;
	esac
}

function read_extra_options() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) check_internet_connection; get_ipv4_list; read_extra_options ;;
		2) check_internet_connection; get_ipv6_list; read_extra_options ;;
		3) reset_main ;;
		4) exit_script ;;
		*) reset_ipvx ;;
	esac
}

function read_extra_options_two() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) make_backup; get_ipv4_list_and_rank; read_extra_options_two ;;
		2) make_backup; get_ipv6_list_and_rank; read_extra_options_two ;;
		3) reset_main ;;
		4) exit_script ;;
		*) reset_ipvx_two ;;
	esac
}

function read_extra_options_three() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) get_ipv4_list_and_rank_country; read_extra_options_three ;;
		2) get_ipv6_list_and_rank_country; read_extra_options_three ;;
		3) reset_main ;;
		4) exit_script ;;
		*) reset_ipvx_three ;;
	esac
}

function mirrors_count() {
 
  read -p "Insert number of mirrors to keep (default=5), and press [ENTER] " -r input_mirrors
  if [[ $input_mirrors =~ ^-?[0-9]+$ ]]; then
    MIRRORS=$input_mirrors
    echo -e "Number of mirrors to keep: ${ORNG}${MIRRORS}${STRD}"
  else
    echo -e "Number of mirrors to keep: ${ORNG}${MIRRORS}${STRD}"
  fi
}

function rank_mirrors_existing() {
  
  mirrors_count
  cp "${PAC_LIST_}" "${PAC_LIST_TMP}"
  start_spinner "Ranking ${GRN}$PAC_LIST_TMP${STRD}..."
  sleep 2
  sed -i 's/^#Server/Server/' $PAC_LIST_TMP
  rankmirrors -n "$MIRRORS" $PAC_LIST_TMP > $PAC_LIST_
  stop_spinner $?
  clear_line
  start_spinner "Updating pacman's database..."
  sleep 2
  pacman -Syy 1> /dev/null
  stop_spinner $?
  clear_line
  echo -e "Done"
}

function rank_mirrors() {
  
  mirrors_count
  start_spinner "Ranking ${GRN}$PAC_LIST_NEW${STRD}..."
  sleep 2
  sed -i 's/^#Server/Server/' $PAC_LIST_NEW
  rankmirrors -n "$MIRRORS" $PAC_LIST_NEW > $PAC_LIST_
  stop_spinner $?
  clear_line
  start_spinner "Updating pacman's database..."
  sleep 2
  pacman -Syy 1> /dev/null
  stop_spinner $?
  clear_line
  echo -e "Done"
}

function get_ipv4_list() {

  start_spinner "Downloading new mirrorlist..."
  sleep 2
  wget -q -O "${PAC_LIST_NEW}" "${IPV4_LIST}"
  stop_spinner $?
  clear_line
  echo -e "Saved as ${GRN}$PAC_LIST_NEW${STRD}"
}

function get_ipv6_list() {
  
  start_spinner "Downloading new mirrorlist..."
  sleep 2
  wget -q -O "${PAC_LIST_NEW}" "${IPV6_LIST}"
  stop_spinner $?
  clear_line
  echo -e "Saved as ${GRN}$PAC_LIST_NEW${STRD}"
}

function get_ipv4_list_and_rank() {

  get_ipv4_list
  rank_mirrors
}

function get_ipv6_list_and_rank() {

  get_ipv6_list
  rank_mirrors
}

function rank_new() {
  
  rank_mirrors
}

function get_ipv4_list_and_rank_country() {
  
  local CHOOSEN_COUNTRY
  local HTTP_CODE
  local URL
  local LOCAL_FILE
  local NUMBER_OF_MIRRORS
  
  read -p "Enter country's ISO code (e.g. US, GR): " -r CHOOSEN_COUNTRY
  CHOOSEN_COUNTRY=$(awk '{print toupper($0)}' <<< "${CHOOSEN_COUNTRY}")
  URL="${COUNTRY_LIST}${CHOOSEN_COUNTRY}${COUNTRY_IPV4_PART}"
  
  start_spinner "Checking ${ARCH_MIRRORLIST}..."
  sleep 2
  HTTP_CODE=$(wget --spider -t 1 --timeout=600 -S "${URL}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
  if [[ "${HTTP_CODE}" = "200" ]]; then
    stop_spinner $?
    clear_line
    LOCAL_FILE="/tmp/madubi-${CHOOSEN_COUNTRY}-ipv4-mirrorlist"
    start_spinner "Checking if ${CHOOSEN_COUNTRY} is available..."
    sleep 2
    wget --quiet "${URL}" -O "${LOCAL_FILE}"
    stop_spinner $?
    clear_line
    if ! grep 'errorlist' "${LOCAL_FILE}" > /dev/null; then
      cp "${LOCAL_FILE}" "${PAC_LIST_NEW}"
      NUMBER_OF_MIRRORS=$(awk '/^#Server/{a++}END{print a}' "${LOCAL_FILE}")
      echo -e "${ORNG}${NUMBER_OF_MIRRORS}${STRD} mirrors found"
      rank_mirrors
    else
      start_spinner "${RED}${CHOOSEN_COUNTRY} is not available${STRD}"
      sleep 2
      wget --quiet "${ARCH_MIRRORLIST}" -O "${LOCAL_FILE}"
      stop_spinner $?
      echo -e "Choose one of the following ISO codes${GRN}"
      cat < "${LOCAL_FILE}" | grep "<option\ value" | sed 's/.*<option\ value=//;s/<\/option>.*//' | sed 's/^"\(.*\)".*/\1/' | tail -n+2 | sed ':a;N;$!ba;s/\n/, /g'
      echo -ne "${STRD}"    
    fi
  else
    stop_spinner $?
    clear_line
    echo -e "${RED}Server has connection issues, it may be down.${STRD}"
  fi
}

function get_ipv6_list_and_rank_country() {
  
  local CHOOSEN_COUNTRY
  local HTTP_CODE
  local URL
  local LOCAL_FILE
  local NUMBER_OF_MIRRORS
    
  read -p "Enter country's ISO code (e.g. US, GR): " -r CHOOSEN_COUNTRY
  CHOOSEN_COUNTRY=$(awk '{print toupper($0)}' <<< "${CHOOSEN_COUNTRY}")
  URL="${COUNTRY_LIST}${CHOOSEN_COUNTRY}${COUNTRY_IPV6_PART}"
  
  start_spinner "Checking ${ARCH_MIRRORLIST}..."
  sleep 2
  HTTP_CODE=$(wget --spider -t 1 --timeout=600 -S "${URL}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
  if [[ "${HTTP_CODE}" = "200" ]]; then
    stop_spinner $?
    clear_line
    LOCAL_FILE="/tmp/madubi-${CHOOSEN_COUNTRY}-ipv6-mirrorlist"
    start_spinner "Checking if ${CHOOSEN_COUNTRY} is available..."
    sleep 2
    wget --quiet "${URL}" -O "${LOCAL_FILE}"
    stop_spinner $?
    clear_line
    if ! grep 'errorlist' "${LOCAL_FILE}" > /dev/null; then
      cp "${LOCAL_FILE}" "${PAC_LIST_NEW}"
      NUMBER_OF_MIRRORS=$(awk '/^#Server/{a++}END{print a}' "${LOCAL_FILE}")
      echo -e "${ORNG}${NUMBER_OF_MIRRORS}${STRD} mirrors found"
      rank_mirrors
    else
      start_spinner "${RED}${CHOOSEN_COUNTRY} is not available${STRD}"
      sleep 2
      wget --quiet "${ARCH_MIRRORLIST}" -O "${LOCAL_FILE}"
      stop_spinner $?
      echo -e "Choose one of the following ISO codes${GRN}"
      cat < "${LOCAL_FILE}" | grep "<option\ value" | sed 's/.*<option\ value=//;s/<\/option>.*//' | sed 's/^"\(.*\)".*/\1/' | tail -n+2 | sed ':a;N;$!ba;s/\n/, /g'
      echo -ne "${STRD}"    
    fi
  else
    stop_spinner $?
    clear_line
    echo -e "${RED}Server has connection issues, it may be down.${STRD}"
  fi
}

function rank_existing() {
  
  if [[ -f "${PAC_LIST_}" ]]; then
    rank_mirrors_existing
  else
    echo -e "${RED}Cannot find mirrorlist in /etc/pacman.d${STRD}"
  fi
}

function rank_existing_country() {
  
  local CHOOSEN_COUNTRY
  local HTTP_CODE
  local LOCAL_FILE
  local NUMBER_OF_MIRRORS
  
  if [[ -f "${PAC_LIST_}" ]]; then    
    read -p "Enter country's ISO code (e.g. US, GR): " -r CHOOSEN_COUNTRY
    CHOOSEN_COUNTRY=$(awk '{print toupper($0)}' <<< "${CHOOSEN_COUNTRY}")
    
    start_spinner "Checking ${ARCH_MIRRORLIST}..."
    sleep 2
    HTTP_CODE=$(wget --spider -t 1 --timeout=600 -S "${ARCH_MIRRORLIST}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
    if [[ "${HTTP_CODE}" = "200" ]]; then
      stop_spinner $?
      clear_line
      LOCAL_FILE="/tmp/madubi-${CHOOSEN_COUNTRY}-ranking-existing-mirrolist"
      start_spinner "Checking if ${CHOOSEN_COUNTRY} is available..."
      sleep 2
      wget --quiet "${URL}" -O "${LOCAL_FILE}"
      stop_spinner $?
      clear_line
      if ! grep 'errorlist' "${LOCAL_FILE}" > /dev/null; then
        NUMBER_OF_MIRRORS=$(awk '/^Server/{a++}END{print a}' ${PAC_LIST_TMP})
        echo -e "${ORNG}${NUMBER_OF_MIRRORS}${STRD} mirrors found"
        rank_mirrors_existing
      else
        start_spinner "${RED}${CHOOSEN_COUNTRY} is not available${STRD}"
        sleep 2
        wget --quiet "${ARCH_MIRRORLIST}" -O "${LOCAL_FILE}"
        stop_spinner $?
        echo -e "Choose one of the following ISO codes${GRN}"
        cat < "${LOCAL_FILE}" | grep "<option\ value" | sed 's/.*<option\ value=//;s/<\/option>.*//' | sed 's/^"\(.*\)".*/\1/' | tail -n+2 | sed ':a;N;$!ba;s/\n/, /g'
        echo -ne "${STRD}"    
      fi
    else
      stop_spinner $?
      clear_line
      echo -e "${RED}Server has connection issues, it may be down.${STRD}"
    fi
  else
    echo -e "${RED}Cannot find mirrorlist in /etc/pacman.d${STRD}"
  fi
}

function init() {
  
  if [[ "${DEBUG}" = "0" ]]; then
    trap trap_handler INT
    trap trap_handler SIGTSTP
    check_pacman
    check_rankmirrors
    check_permissions
    check_bash_version
    check_internet_connection
    intro
  fi
  
  main_menu
  
  while [[ "${MAIN_MENU_CHECK}" -eq "1" ]]; do
    read_main_options
  done

  while [[ "${EXTRA_MENU_CHECK}" -eq "1" ]]; do
    read_extra_options
  done
}

init
