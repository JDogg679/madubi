#!/bin/bash
#### Description......: Menu driven pacman's mirrorlist updater.
#### Written by.......: Sotirios Roussis (aka. xtonousou) - xtonousou@gmail.com on 11-2016
#### Name.............: madubi that means mirror in Hausa

# DEBUG=1 to skip intro, checking functions and traps
DEBUG=1

# colors
GRN="\033[1;32m"
RED="\033[1;31m"
ORNG="\033[1;33m"
STRD="\e[1;0m"

# pacman locations
PAC_LIST_NEW="/etc/pacman.d/mirrorlist.pacnew"
PAC_LIST_OLD="/etc/pacman.d/mirrorlist.old"
PAC_LIST_TMP="/etc/pacman.d/mirrorlist.tmp"
PAC_LIST_="/etc/pacman.d/mirrorlist"
PAC_DIR="/etc/pacman.d"

# checkers
MAIN_MENU_CHECK="1"
EXTRA_MENU_CHECK="0"

# default values
AUTHOR="Sotirios Roussis"
AUTHOR_NICKNAME="xtonousou"
GMAIL="${AUTHOR_NICKNAME}@gmail.com"
GITHUB="https://github.com/${AUTHOR_NICKNAME}"
VERSION="1.3"
GOOGLE_DNS="8.8.4.4"
ARCH_MIRRORLIST="https://www.archlinux.org/mirrorlist/"
COUNTRY_LIST="${ARCH_MIRRORLIST}?country="
COUNTRY_IPV4_PART="&protocol=http&ip_version=4"
COUNTRY_IPV6_PART="&protocol=http&ip_version=6"
IPV4_LIST="${ARCH_MIRRORLIST}?ip_version=4"
IPV6_LIST="${ARCH_MIRRORLIST}?ip_version=6"
MIRRORS="6"
RETURNED_VALUE="0"

# workarounds
IFS=$'\n' # passing values to arrays (internal field separator)

function check_permissions() {
  
  if [[ "$(id -u)" -ne "0" ]]; then
     echo -e "${RED}error${STRD}: you cannot perform this operation unless you are root."
     exit 1
  fi
}

function check_internet_connection() {
  
  ping -c 1 -W 3 "${GOOGLE_DNS}" > /dev/null 2>&1 && return 1 || \
  echo -e "${ORNG}warning${STRD}: internet connection unavailable."
}

# Checks for compatible bash versions. Needs fixing...
function check_bash_version() {
  
  if bash --version | grep -Eo "4.[0-9].[0-9][0-9]\([0-9]\)" | grep "^[0-3]"; then
    echo -e "${RED}error${STRD}: insufficient bash version. You must have bash with version 4 or later."
    exit 1
  fi
}

function check_pacman() {
  
  ! hash pacman 2> /dev/null && \
  echo -e "${RED}error${STRD}: package manager is not ${ORNG}pacman${STRD}." \
  exit 1
}

function check_rankmirrors() {
  
  ! hash rankmirrors 2> /dev/null && \
  echo -e "${RED}error${STRD}: \"rankmirrors\" command not found." \
  exit 1
}

function check_if_in_array () {
  
  local ITEM
  
  # return 1 if passed value exists in array
  for ITEM in "${@:2}"; do [[ "$ITEM" == "$1" ]] && return 1; done
  return 0
}

function make_backup() {
  
  local CHOICE
  
  if ! [[ -f "${PAC_LIST_OLD}" ]]; then
    start_spinner "Backing up \"${GRN}${PAC_LIST_}${STRD}\""
    sleep 2
    cp "${PAC_LIST_}" "${PAC_LIST_OLD}"
    clear_line
    stop_spinner $?
    echo -e "A backup has been created \"${GRN}${PAC_LIST_OLD}${STRD}\""
  else
    echo -e "${ORNG}warning${STRD}: a backup already exists"
    CHOICE=""
    while [[ ! "${CHOICE}" =~ ^[YyNn]$ ]]; do
      echo -e "Are you sure you want to replace \"${GRN}${PAC_LIST_OLD}${STRD}\" ?"
      echo -ne "Enter [y/n] and press [ENTER] "
      read -r CHOICE
    done
    if [[ "${CHOICE}" == "Y" ]]; then
      CHOICE="y"
    elif [[ "${CHOICE}" == "N" ]]; then
      CHOICE="n"
    fi
    if [[ "${CHOICE}" == "y" ]]; then
      start_spinner "Backing up \"${GRN}${PAC_LIST_}${STRD}\""
      sleep 2
      cp "${PAC_LIST_}" "${PAC_LIST_OLD}"
      clear_line
      stop_spinner $?
      echo -e "A new backup has been replaced \"${GRN}${PAC_LIST_OLD}${STRD}\""
    else
      reset_screen "main"      
    fi
  fi
}

function revert_mirrorlist() {
  
  local CHOICE
  
  if [[ -f "${PAC_LIST_OLD}" ]]; then
    CHOICE=""
    while [[ ! "${CHOICE}" =~ ^[YyNn]$ ]]; do
      echo -e "Are you sure you want to revert \"${GRN}${PAC_LIST_}${STRD}\" ?"
      echo -ne "Enter [y/n] and press [ENTER] "
      read -r CHOICE
    done
    if [[ "${CHOICE}" == "Y" ]]; then
      CHOICE="y"
    elif [[ "${CHOICE}" == "N" ]]; then
      CHOICE="n"
    fi
    if [[ "${CHOICE}" == "y" ]]; then
      start_spinner "Reverting from \"${GRN}${PAC_LIST_OLD}${STRD}\" ..."
      sleep 2
      cp "${PAC_LIST_OLD}" "${PAC_LIST_}"
      clear_line
      stop_spinner $?
      echo -e "Mirrorlist is now the way it was on \"${GRN}${PAC_LIST_OLD}${STRD}\""
    else
      reset_screen "main"
    fi
  else
    echo -e "${ORNG}warning${STRD}: backup does not exist in \"${GRN}${PAC_DIR}${STRD}\""
    echo -e "Select \"${GRN}Backup${STRD}\" option from \"${ORNG}Main Menu${STRD}\" to make one"
    reset_screen "main"      
  fi 
}

function reset_screen() {
  
  local ENTER
  
  read -p "Press [ENTER] to refresh: " -r ENTER
  if [[ "$1" == "ipvx" ]]; then
    ipvx_menu
    read_extra_options
  elif [[ "$1" == "ipvx_two" ]]; then
    ipvx_menu
    read_extra_options_two
  elif [[ "$1" == "ipvx_three" ]]; then
    ipvx_menu
    read_extra_options
  else
    main_menu
    read_main_options
  fi
}

function return_to() {
  
  if [[ "$1" == "ipvx" ]]; then
    ipvx_menu
    read_extra_options
  elif [[ "$1" == "ipvx_two" ]]; then
    ipvx_menu
    read_extra_options_two
  elif [[ "$1" == "ipvx_three" ]]; then
    ipvx_menu
    read_extra_options
  else
    main_menu
    read_main_options
  fi
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
    stop) kill "$3" > /dev/null 2>&1; ;;
    *) echo "Invalid argument!"; exit 1; ;;
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
  
  rm -f "${PAC_LIST_TMP}" /tmp/madubi* 
}

function exit_script() {
  
  clear
  start_spinner "Cleaning temp files ..."
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
		reset_screen "main"
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
  sleep 1.5
}

function main_menu() {
  
  clear
  echo    "                     ┌───────────┐"
  echo -e "┌────────────────────┤ ${ORNG}Main Menu${STRD} ├─────────────────────┐"
  echo    "│                    └───────────┘                     │"
  echo -e "│ ${GRN}1${STRD})  Download new mirrorlist                          │"
  echo -e "│ ${GRN}2${STRD})  Download and rank new mirrorlist                 │"
  echo -e "│ ${GRN}3${STRD})  Download and rank new mirrorlist (Country based) │"
  echo -e "│ ${GRN}4${STRD})  Rank new mirrorlist                              │"
  echo -e "│ ${GRN}5${STRD})  Rank new mirrorlist (Country based)              │"
  echo -e "│ ${GRN}6${STRD})  Rank existing mirrorlist                         │"
  echo -e "│ ${GRN}7${STRD})  Rank existing mirrorlist (Country based)         │"
  echo -e "│ ${GRN}8${STRD})  Backup                                           │"
  echo -e "│ ${GRN}9${STRD})  Reset                                            │"
  echo -e "│ ${GRN}10${STRD}) Exit                                             │"
  echo    "└──────────────────────────────────────────────────────┘"
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
	read -p "Enter choice [1-8] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then ipvx_menu; read_extra_options;
        else reset_screen "main"; fi ;;
		2)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then ipvx_menu; read_extra_options_two;
        else reset_screen "main"; fi ;;
		3)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then ipvx_menu; read_extra_options_three;
        else reset_screen "main"; fi ;;
		4)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then rank_new; reset_screen "main";
        else reset_screen "main"; fi ;;
		5)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then rank_new_country; reset_screen "main";
        else reset_screen "main"; fi ;;
		6)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then rank_existing; reset_screen "main";
        else reset_screen "main"; fi ;;
		#7)  check_internet_connection
    #    if [[ "$?" -eq 1 ]]; then rank_existing_country; reset_screen "main";
    #    else reset_screen "main"; fi ;;
		7)  rank_existing_country; reset_screen "main"; ;;
    8)  make_backup; reset_screen "main" ;;
		9)  revert_mirrorlist; reset_screen "main" ;;
		10) exit_script ;;
		*)  return_to "main" ;;
	esac
}

function read_extra_options() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_ipv4_list; reset_screen "ipvx";
       else reset_screen "ipvx"; fi ;;
		2) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_ipv6_list; reset_screen "ipvx";
       else reset_screen "ipvx"; fi ;;
		3) return_to "main" ;;
		4) exit_script ;;
		*) return_to "ipvx" ;;
	esac
}

function read_extra_options_two() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_ipv4_list_and_rank; reset_screen "ipvx_two";
       else reset_screen "ipvx_two"; fi ;;
		2) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_ipv6_list_and_rank; reset_screen "ipvx_two";
       else reset_screen "ipvx_two"; fi ;;
		3) return_to "main" ;;
		4) exit_script ;;
		*) return_to "ipvx_two";;
	esac
}

function read_extra_options_three() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_ipv4_list_and_rank_country; reset_screen "ipvx_three";
       else reset_screen "ipvx_three"; fi ;;
		2) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_ipv6_list_and_rank_country; reset_screen "ipvx_three";
       else reset_screen "ipvx_three"; fi ;;
		3) return_to "main" ;;
		4) exit_script ;;
		*) return_to "ipvx_three";;
	esac
}

# TODO: needs fixing 0 mirrors on input is accepted
# Reads number of mirrors to keep before ranking, calculates
# and echoes what user should know about
function mirrors_count() {
  
  local INPUT_MIRRORS
  
  INPUT_MIRRORS=""
  
  # if not number of servers of mirrolist has been passed
  if [[ -z "$1" ]]; then
    # while input is not number, read
    while ! [[ "${INPUT_MIRRORS}" =~ ^[0-9]+$ ]]; do
      echo -ne "Enter mirrors to keep (recommended=${ORNG}${MIRRORS}${STRD}), and press [ENTER] "
      read -r INPUT_MIRRORS
    done
    # if default value of mirrors is less than input
    # replace input with the default value
    if [[ "${MIRRORS}" -lt "${INPUT_MIRRORS}" ]]; then INPUT_MIRRORS="${MIRRORS}"; fi
    if [[ "${INPUT_MIRRORS}" -eq 1 ]]; then echo -e "Will keep: ${ORNG}${INPUT_MIRRORS}${STRD} mirror";
    else echo -e "Will keep: ${ORNG}${INPUT_MIRRORS}${STRD} mirrors"; fi
  # if number of servers of mirrolist has been passed
  else
    # if passed value is less than the default, switch values
    if [[ "$1" -lt "${MIRRORS}" ]]; then MIRRORS="$1"; fi
    # while input is not number, read
    while ! [[ "${INPUT_MIRRORS}" =~ ^[0-9]+$ ]]; do
      echo -ne "Enter mirrors to keep (recommended=${ORNG}${MIRRORS}${STRD}), and press [ENTER] "
      read -r INPUT_MIRRORS
    done
    # if default value (previously switched with a passed value)
    # is less than input value, switch values
    if [[ "${MIRRORS}" -lt "${INPUT_MIRRORS}" ]]; then INPUT_MIRRORS="${MIRRORS}"; fi
    if [[ "${INPUT_MIRRORS}" -eq 1 ]]; then echo -e "Will keep: ${ORNG}${INPUT_MIRRORS}${STRD} mirror";
    else echo -e "Will keep: ${ORNG}${INPUT_MIRRORS}${STRD} mirrors"; fi
  fi
}

function rank_mirrors_country() {

  local CHOOSEN_COUNTRY
  local HTTP_CODE
  local URL
  local LOCAL_FILE
  local NUMBER_OF_MIRRORS
  
  read -p "Enter country's ISO code (e.g. US, GR): " -r CHOOSEN_COUNTRY
  CHOOSEN_COUNTRY=$(awk '{print toupper($0)}' <<< "${CHOOSEN_COUNTRY}")
  start_spinner "Checking ${ARCH_MIRRORLIST} ..."
  sleep 2
  HTTP_CODE=$(wget --spider -t 1 --timeout=10 -S "${ARCH_MIRRORLIST}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
  if [[ "${HTTP_CODE}" = 200 ]]; then
    stop_spinner $?
    clear_line
    start_spinner "Checking if ${CHOOSEN_COUNTRY} is available ..."
    sleep 2
    stop_spinner $?
    clear_line
    if ! grep 'errorlist' "${LOCAL_FILE}" > /dev/null; then
      NUMBER_OF_MIRRORS=$(awk '/^Server/{a++}END{print a}' ${PAC_LIST_TMP})
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

function rank_mirrors_existing() {
  
  mirrors_count "$1"
  cp "${PAC_LIST_}" "${PAC_LIST_TMP}"
  if [[ -z "$2" ]]; then
    start_spinner "Ranking ${GRN}$PAC_LIST_TMP${STRD} ..."
  else
    start_spinner "Ranking ${GRN}$PAC_LIST_TMP${STRD} based on [${GRN}$2${STRD}] ..."
  fi
  sleep 2
  # uncomment servers
  sed -i 's/^#Server/Server/' $PAC_LIST_TMP
  # rank servers
  rankmirrors -n "$MIRRORS" $PAC_LIST_TMP > $PAC_LIST_
  stop_spinner $?
  clear_line
  start_spinner "Updating pacman's database ..."
  sleep 2
  # update db
  pacman -Syy 1> /dev/null
  stop_spinner $?
  clear_line
  echo -e "Done"
}

function rank_mirrors() {
  
  mirrors_count
  start_spinner "Ranking ${GRN}$PAC_LIST_NEW${STRD} ..."
  sleep 2
  sed -i 's/^#Server/Server/' $PAC_LIST_NEW
  rankmirrors -n "$MIRRORS" $PAC_LIST_NEW > $PAC_LIST_
  stop_spinner $?
  clear_line
  start_spinner "Updating pacman's database ..."
  sleep 2
  pacman -Syy 1> /dev/null
  stop_spinner $?
  clear_line
  echo -e "Done"
}

function get_ipv4_list() {

  start_spinner "Downloading new mirrorlist ..."
  sleep 2
  wget -q -O "${PAC_LIST_NEW}" "${IPV4_LIST}"
  stop_spinner $?
  clear_line
  echo -e "Saved as ${GRN}$PAC_LIST_NEW${STRD}"
}

function get_ipv6_list() {
  
  start_spinner "Downloading new mirrorlist ..."
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

function rank_new_country() {
  
  rank_mirrors_country
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
  
  start_spinner "Checking ${ARCH_MIRRORLIST} ..."
  sleep 2
  HTTP_CODE=$(wget --spider -t 1 --timeout=10 -S "${URL}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
  if [[ "${HTTP_CODE}" = 200 ]]; then
    stop_spinner $?
    clear_line
    LOCAL_FILE="/tmp/madubi-${CHOOSEN_COUNTRY}-ipv4-mirrorlist"
    start_spinner "Checking if ${CHOOSEN_COUNTRY} is available ..."
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

# Download new IPv6 mirrorlist from https://www.archlinux.org/mirrorlist
# and rank it based on Country or Worldwide.
function get_ipv6_list_and_rank_country() {
  
  local CHOOSEN_COUNTRY
  local HTTP_CODE
  local URL
  local NUMBER_OF_MIRRORS
  
  # read
  read -p "Enter country's ISO code (e.g. US, GR): " -r CHOOSEN_COUNTRY
  # capitalize it
  CHOOSEN_COUNTRY=$(awk '{print toupper($0)}' <<< "${CHOOSEN_COUNTRY}")
  # assemble URL from substituted parts including input
  URL="${COUNTRY_LIST}${CHOOSEN_COUNTRY}${COUNTRY_IPV6_PART}"
  
  start_spinner "Checking ${ARCH_MIRRORLIST}..."
  sleep 2
  # get HTTP code from assembled URL
  HTTP_CODE=$(wget --spider -t 1 --timeout=10 -S "${URL}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
  # if HTTP CODE is 200
  if [[ "${HTTP_CODE}" = 200 ]]; then
    stop_spinner $?
    clear_line
    start_spinner "Checking if ${CHOOSEN_COUNTRY} is available ..."
    sleep 2
    # download mirrorlist including input
    wget --quiet "${URL}" -O "${PAC_LIST_TMP}"
    stop_spinner $?
    clear_line
    # if 'errorlist' does not exist somewhere in the HTML file
    # it means that input was valid and does exist in there
    if ! grep 'errorlist' "${PAC_LIST_TMP}" > /dev/null; then
      # find how many mirrors exists for selected option (commented or not)
      NUMBER_OF_MIRRORS=$(awk -v COUNT=0 "/^#Server/||/^Server/{COUNT++}END{print COUNT}" "${PAC_LIST_TMP}")
      echo -e "${ORNG}${NUMBER_OF_MIRRORS}${STRD} mirrors found"
      # copy temp mirrorlist to .pacnew
      cp "${PAC_LIST_TMP}" "${PAC_LIST_NEW}"
      # rank mirrorlist
      rank_mirrors
    # if 'errorlist' does exist in the HTML file
    # it means that input was invalid and it does not exist in there
    else
      start_spinner "${RED}${CHOOSEN_COUNTRY} is not available${STRD}"
      sleep 2
      # download the HTML file to parse available options
      wget --quiet "${ARCH_MIRRORLIST}" -O "${PAC_LIST_TMP}"
      stop_spinner $?
      echo -e "Choose one of the following ISO codes${GRN}"
      # display available options
      cat < "${PAC_LIST_TMP}" | grep "<option\ value" | sed 's/.*<option\ value=//;s/<\/option>.*//' | sed 's/^"\(.*\)".*/\1/' | tail -n+2 | sed ':a;N;$!ba;s/\n/, /g'
      echo -ne "${STRD}"    
    fi
  # if HTTP CODE is not 200
  else
    stop_spinner $?
    clear_line
    echo -e "${RED}Server has connection issues, it may be down.${STRD}"
  fi
}

# Ranks existing /etc/pacman.d/mirrorlist.
function rank_existing() {
  
  # if /etc/pacman.d/mirrorlist exists then rank it
  # else print error
  if [[ -f "${PAC_LIST_}" ]]; then
    rank_mirrors_existing
  else
    echo -e "${RED}Cannot find mirrorlist in ${PAC_DIR}${STRD}"
  fi
}

# Ranks existing /etc/pacman.d/mirrorlist based on country or worldwide.
function rank_existing_country() {
  
  local CHOOSEN_COUNTRY
  
  declare -a AVAILABLE_OPTIONS
    
  if [[ -f "${PAC_LIST_}" ]]; then
    # make a copy of the current mirrolist
    cp "${PAC_LIST_}" "${PAC_LIST_TMP}"
    # if "Arch Linux repository mirrorlist" exists somewhere in mirrorlist, 
    # it means that mirrorlist is new or it is not yet parsed by madubi
    grep -i "Arch Linux repository mirrorlist" "${PAC_LIST_TMP}" > /dev/null 2>&1 && \
    sed -i '1,4d' "${PAC_LIST_TMP}" # if true, remove first four lines
    # keep only lines starting with double hashtag
    sed -n -i 's/^## //p' "${PAC_LIST_TMP}"
    # pass values from file to array
    AVAILABLE_OPTIONS=($(<"${PAC_LIST_TMP}"))
    # if options are available, print them out
    if [[ "${#AVAILABLE_OPTIONS[@]}" -ge 1 ]]; then
      for i in "${!AVAILABLE_OPTIONS[@]}"; do
        echo -ne "[${GRN}${AVAILABLE_OPTIONS[i]}${STRD}] "
      done
      echo
      while ! [[ "${RETURNED_VALUE}" -eq 1 ]]; do
        # read input
        read -p "Enter country: " -r CHOOSEN_COUNTRY
        # convert to lowercase
        CHOOSEN_COUNTRY=$(awk '{print tolower($0)}' <<< "${CHOOSEN_COUNTRY}")
        # capitalize first letter
        CHOOSEN_COUNTRY=$(sed -e "s/\b\(.\)/\u\1/g" <<< "${CHOOSEN_COUNTRY}")
        # validate input check if it exists in array
        check_if_in_array "${CHOOSEN_COUNTRY}" "${AVAILABLE_OPTIONS[@]}"
        RETURNED_VALUE="$?"
      done
      # extract only the prefered part
      awk "/${CHOOSEN_COUNTRY}/,/^$/" "${PAC_LIST_}" > "${PAC_LIST_TMP}" 
      # find how many mirrors exists for selected option (commented or not)
      NUMBER_OF_MIRRORS=$(awk -v COUNT=0 "/^#Server/||/^Server/{COUNT++}END{print COUNT}" "${PAC_LIST_TMP}")
      echo -e "${ORNG}${NUMBER_OF_MIRRORS}${STRD} mirrors found for [${GRN}${CHOOSEN_COUNTRY}${STRD}]"
      # copy modified mirrorlist to the existing one 
      cp "${PAC_LIST_TMP}" "${PAC_LIST_}"
      # rank mirrors
      rank_mirrors_existing "${NUMBER_OF_MIRRORS}" "${CHOOSEN_COUNTRY}"
    else
      echo -e "${RED}error${STRD}: \"${GRN}${PAC_LIST_}${STRD}\" does not contain any server."    
    fi
  else
    echo -e "${RED}Cannot find mirrorlist in ${PAC_DIR}${STRD}"
  fi
}

# Initializes the script.
function init() {
  
  # if "DEBUG" is on, ignores traps and checking functions
  if [[ "${DEBUG}" -eq 0 ]]; then
    trap trap_handler INT
    trap trap_handler SIGTSTP
    check_pacman
    check_rankmirrors
    check_permissions
    check_bash_version
    intro
  fi
  
  # prints out the main_menu
  main_menu
  
  # this will maintain reading steps in sane (main menu)
  while [[ "${MAIN_MENU_CHECK}" -eq 1 ]]; do
    read_main_options
  done

  # this will maintain reading steps in sane (extra menus)
  while [[ "${EXTRA_MENU_CHECK}" -eq 1 ]]; do
    read_extra_options
  done
}

init
