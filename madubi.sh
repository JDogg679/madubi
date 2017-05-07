#!/bin/bash
#### Description .....: Menu driven pacman's mirrorlist updater.
#### Written by ......: Sotirios Roussis (aka. xtonousou) - xtonousou@gmail.com on 11-2016
#### Script's Name ...: madubi
### 1. Insert message for invalid input 
### 2. use an exit button no matter what the menu
# DEBUG=1 to skip intro, checking functions and traps
DEBUG=0

# workarounds
IFS=$'\n' # passing values to arrays (internal field separator)

# colors
RED="\033[1;31m"
GRN="\033[1;32m"
ORNG="\033[1;33m"
BLUE="\033[1;34m"
PINK="\033[1;35m"
STRD="\e[1;0m"

# pacman locations
PAC_LIST_NEW="/etc/pacman.d/mirrorlist.pacnew"
PAC_LIST_OLD="/etc/pacman.d/mirrorlist.old"
PAC_LIST_TMP="/etc/pacman.d/temp.tmp"
PAC_LIST_TMP_TWO="/etc/pacman.d/temp_two.tmp"
PAC_LIST_="/etc/pacman.d/mirrorlist"
PAC_DIR="/etc/pacman.d"

# default values
AUTHOR="Sotirios Roussis"
AUTHOR_NICKNAME="xtonousou"
GMAIL="${AUTHOR_NICKNAME}@gmail.com"
GITHUB="https://github.com/${AUTHOR_NICKNAME}"
VERSION="1.4"
GOOGLE_DNS="8.8.4.4"
ARCH_MIRRORLIST="https://www.archlinux.org/mirrorlist/"
COUNTRY_LIST="${ARCH_MIRRORLIST}?country="
COUNTRY_IPV4_PART="&protocol=http&ip_version=4"
COUNTRY_IPV6_PART="&protocol=http&ip_version=6"
IPV4_LIST="${ARCH_MIRRORLIST}?ip_version=4"
IPV6_LIST="${ARCH_MIRRORLIST}?ip_version=6"
MIRRORS=6

# shared values
MIRRORS_FOUND=0
RETURNED_VALUE=0
MAIN_MENU_CHECK=1
EXTRA_MENU_CHECK=0

# Checks for root permissions.
function check_permissions() {
  
  if [[ "$(id -u)" -ne "0" ]]; then
     echo -e "${RED}error${STRD}: you cannot perform this operation unless you are root."
     exit 1
  fi
}

# Checks internet connection.
function check_internet_connection() {
  
  ping -c 1 -W 3 "${GOOGLE_DNS}" > /dev/null 2>&1 && return 1 || \
  echo -e "${ORNG}warning${STRD}: internet connection unavailable."
}

# Checks if bash version is compatible.
function check_bash_version() {
  
  if [[ $(echo "${BASH_VERSINFO}") -lt 4 ]]; then
    echo -e "${RED}error${STRD}: insufficient bash version. You must have bash with version 4 or later."
    exit 1
  fi
}

# Checks if the package manager is pacman.
function check_pacman() {
  
  ! hash pacman 2> /dev/null && \
  echo -e "${RED}error${STRD}: package manager is not ${ORNG}pacman${STRD}." && \
  exit 1
}

# Checks if the script "rankmirrors" exists.
function check_rankmirrors() {
  
  ! hash rankmirrors 2> /dev/null && \
  echo -e "${RED}error${STRD}: \"rankmirrors\" command not found." && \
  exit 1
}

# Checks if passed value exists in an array.
function check_if_in_array () {
  
  local ITEM
  
  # return 1 if passed value exists in array
  for ITEM in "${@:2}"; do [[ "$ITEM" == "$1" ]] && return 1; done
  return 0
}

# Makes a backup file of the current pacman mirrorlist.
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

# Reverts pacman mirrorlist from backup located in pacman dir.
# Backup filename: mirrorlist.old
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

# Resets screen based on where the user is at a time.
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

# Responsible for returning to other menu or previous menu.
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

# Removes current line (where cursor is).
# TODO: handle different window sizes... 
function clear_line() {
  
  printf "\r\033[K"
}

# Responsible for showing spinner near a long running task.
function spinner() {
  
  # $1 start/stop
  #
  # on start: $2 display message
  # on stop : $2 process exit status
  #           $3 spinner function pid (supplied from stop_spinner)
  
  local STEP
  local SPINNER_PARTS
  local DELAY

  case "$1" in
    "start")
      # calculate the column where spinner and status msg will be displayed
      let COLUMN=$(tput cols)-${#2}-8
      # display message and position the cursor in $COLUMN column
      echo -ne "${2}"
      printf "%${COLUMN}s"

      # start spinner
      STEP=1
      SPINNER_PARTS='\|/-'
      DELAY="${SPINNER_DELAY:-0.15}"

      while :
      do
        printf "\b%s" "${SPINNER_PARTS:STEP++%${#SPINNER_PARTS}:1}"
        sleep "${DELAY}"
      done
    ;;
    "stop") kill "$3" > /dev/null 2>&1; ;;
    *) echo "Invalid argument!"; exit 1; ;;
  esac
}

# Starts spinner.
function start_spinner {
  
  # $1 : msg to display
  spinner "start" "${1}" &
  # set global spinner pid
  SPINNER_ID=$!
  disown
}

# Stops spinner.
function stop_spinner {
  
  # $1 : command exit status
  spinner "stop" "$1" "${SPINNER_ID}"
  unset SPINNER_ID
}

# Removes all temp files from pacman dir.
function mr_proper() {
  
  rm -f /etc/pacman.d/*.tmp
}

# Cleans on exit.
function exit_script() {
  
  clear
  start_spinner "Cleaning temp files ···${ORNG}•${STRD}··· ${ORNG}ᗤ ${PINK}ᗣ${BLUE} ᗣ${ORNG} ᗣ${RED} ᗣ${STRD}"
  sleep 2
  mr_proper
  stop_spinner $?
  clear_line
  exit 0
}

# Handle 
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

# Initialize associative country array.
function init_matching_country_array() {
  
  # matching countries with ISO codes
  # (used to download mirrorlists based on Country)
  declare -gA MATCHING_COUNTRIES

  MATCHING_COUNTRIES["All"]="all"
  MATCHING_COUNTRIES["Australia"]="AU"
  MATCHING_COUNTRIES["Austria"]="AT"
  MATCHING_COUNTRIES["Belarus"]="BY"
  MATCHING_COUNTRIES["Belgium"]="BE"
  MATCHING_COUNTRIES["Bosnia and Herzegovina"]="BA"
  MATCHING_COUNTRIES["Brazil"]="BR"
  MATCHING_COUNTRIES["Bulgaria"]="BG"
  MATCHING_COUNTRIES["Canada"]="CA"
  MATCHING_COUNTRIES["Chile"]="CL"
  MATCHING_COUNTRIES["China"]="CN"
  MATCHING_COUNTRIES["Colombia"]="CO"
  MATCHING_COUNTRIES["Croatia"]="HR"
  MATCHING_COUNTRIES["Czech Republic"]="CZ"
  MATCHING_COUNTRIES["Denmark"]="DK"
  MATCHING_COUNTRIES["Ecuador"]="EC"
  MATCHING_COUNTRIES["Finland"]="FI"
  MATCHING_COUNTRIES["France"]="FR"
  MATCHING_COUNTRIES["Germany"]="DE"
  MATCHING_COUNTRIES["Greece"]="GR"
  MATCHING_COUNTRIES["Hong Kong"]="HK"
  MATCHING_COUNTRIES["Hungary"]="HU"
  MATCHING_COUNTRIES["Iceland"]="IS"
  MATCHING_COUNTRIES["India"]="IN"
  MATCHING_COUNTRIES["Indonesia"]="ID"
  MATCHING_COUNTRIES["Iran"]="IR"
  MATCHING_COUNTRIES["Ireland"]="IE"
  MATCHING_COUNTRIES["Israel"]="IL"
  MATCHING_COUNTRIES["Italy"]="IT"
  MATCHING_COUNTRIES["Japan"]="JP"
  MATCHING_COUNTRIES["Kazakhstan"]="KZ"
  MATCHING_COUNTRIES["Latvia"]="LV"
  MATCHING_COUNTRIES["Lithuania"]="LT"
  MATCHING_COUNTRIES["Luxembourg"]="LU"
  MATCHING_COUNTRIES["Macedonia"]="MK"
  MATCHING_COUNTRIES["Netherlands"]="NL"
  MATCHING_COUNTRIES["New Caledonia"]="NC"
  MATCHING_COUNTRIES["New Zealand"]="NZ"
  MATCHING_COUNTRIES["Norway"]="NO"
  MATCHING_COUNTRIES["Philippines"]="PH"
  MATCHING_COUNTRIES["Poland"]="PL"
  MATCHING_COUNTRIES["Portugal"]="PT"
  MATCHING_COUNTRIES["Qatar"]="QA"
  MATCHING_COUNTRIES["Romania"]="RO"
  MATCHING_COUNTRIES["Russia"]="RU"
  MATCHING_COUNTRIES["Serbia"]="RS"
  MATCHING_COUNTRIES["Singapore"]="SG"
  MATCHING_COUNTRIES["Slovakia"]="SK"
  MATCHING_COUNTRIES["Slovenia"]="SI"
  MATCHING_COUNTRIES["South Africa"]="ZA"
  MATCHING_COUNTRIES["South Korea"]="KR"
  MATCHING_COUNTRIES["Spain"]="ES"
  MATCHING_COUNTRIES["Sweden"]="SE"
  MATCHING_COUNTRIES["Switzerland"]="CH"
  MATCHING_COUNTRIES["Taiwan"]="TW"
  MATCHING_COUNTRIES["Thailand"]="TH"
  MATCHING_COUNTRIES["Turkey"]="TR"
  MATCHING_COUNTRIES["Ukraine"]="UA"
  MATCHING_COUNTRIES["United Kingdom"]="GB"
  MATCHING_COUNTRIES["United States"]="US"
  MATCHING_COUNTRIES["Vietnam"]="VN"
}

# Print out madubi intro.
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

# Print out primary option menu.
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
  echo -e "│ ${GRN}8${STRD})  Output mirrors and their response time           │"
  echo -e "│ ${GRN}9${STRD})  Backup                                           │"
  echo -e "│ ${GRN}10${STRD}) Reset                                            │"
  echo -e "│ ${GRN}11${STRD}) Exit                                             │"
  echo    "└──────────────────────────────────────────────────────┘"
}

# Print out secondary option menu.
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

# Read option from user.
function read_main_options() {

  local CHOICE
  
  MAIN_MENU_CHECK="1"
  EXTRA_MENU_CHECK="0"
	read -p "Enter choice [1-11] and press [ENTER] " -r CHOICE
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
        if [[ "$?" -eq 1 ]]; then rank_new "normal"; reset_screen "main";
        else reset_screen "main"; fi ;;
		5)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then rank_new "country"; reset_screen "main";
        else reset_screen "main"; fi ;;
		6)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then rank_existing "normal"; reset_screen "main";
        else reset_screen "main"; fi ;;
		7)  check_internet_connection
        if [[ "$?" -eq 1 ]]; then rank_existing "country"; reset_screen "main";
        else reset_screen "main"; fi ;;
    8)  show_info ;;
    9)  make_backup; reset_screen "main" ;;
		10) revert_mirrorlist; reset_screen "main" ;;
		11) exit_script ;;
    *) echo "Invalid choice" ; sleep 1.25 ;
    return_to "main" ;;
    esac
}

# Read option from user.
function read_extra_options() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_list "ipv4"; reset_screen "ipvx";
       else reset_screen "ipvx"; fi ;;
		2) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_list "ipv6"; reset_screen "ipvx";
       else reset_screen "ipvx"; fi ;;
		3) return_to "main" ;;
		4) exit_script ;;
		*) return_to "ipvx" ;;
	esac
}

# Read option from user.
function read_extra_options_two() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_list "ipv4" "rank"; reset_screen "ipvx_two";
       else reset_screen "ipvx_two"; fi ;;
		2) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_list "ipv6" "rank"; reset_screen "ipvx_two";
       else reset_screen "ipvx_two"; fi ;;
		3) return_to "main" ;;
		4) exit_script ;;
		*) return_to "ipvx_two";;
	esac
}

# Read option from user.
function read_extra_options_three() {

  local CHOICE
  
  MAIN_MENU_CHECK="0"
  EXTRA_MENU_CHECK="1"
	read -p "Enter choice [1-4] and press [ENTER] " -r CHOICE
	case $CHOICE in
		1) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_list "ipv4" "rank" "country"; reset_screen "ipvx_three";
       else reset_screen "ipvx_three"; fi ;;
		2) check_internet_connection
       if [[ "$?" -eq 1 ]]; then get_list "ipv6" "rank" "country"; reset_screen "ipvx_three";
       else reset_screen "ipvx_three"; fi ;;
		3) return_to "main" ;;
		4) exit_script ;;
		*) return_to "ipvx_three";;
	esac
}

# Pass mirrorlist ($1) and update MIRRORS_FOUND value with 
# mirrors count of passed mirrolist.
# MIRRORS_FOUND is how many mirrors are found in a mirrorlist.
function update_mirrors_count() {
  
  MIRRORS_FOUND=$(awk -v COUNT=0 "/^#Server/||/^Server/{COUNT++}END{print COUNT}" "$1")
}

# Reads number of mirrors to keep before ranking, calculates
# and echoes what user should know about.
function rank_mirrors() {
  
  local INPUT_MIRRORS
  
  # while input is not number, read
  while ! [[ "${INPUT_MIRRORS}" =~ ^[0-9]+$ ]]; do
    echo -ne "Enter number of servers to output, 0 for all, and press [ENTER] "
    read -r INPUT_MIRRORS
  done
  # if mirrors found are less than the default, switch values
  if [[ "${MIRRORS_FOUND}" -lt "${MIRRORS}" ]]; then MIRRORS="${MIRRORS_FOUND}"; fi
  # if default value is less than input value, switch values
  if [[ "${MIRRORS}" -lt "${INPUT_MIRRORS}" ]]; then INPUT_MIRRORS="${MIRRORS}"; fi
  # if input mirrors is 0, accept all mirrors in list
  if [[ "${INPUT_MIRRORS}" -eq 0 ]]; then INPUT_MIRRORS="${MIRRORS_FOUND}"; fi
  # handle proper echo
  if [[ "${INPUT_MIRRORS}" -eq 1 ]]; then echo -e "Will keep: ${ORNG}${INPUT_MIRRORS}${STRD} mirror";
  else echo -e "Will keep: ${ORNG}${INPUT_MIRRORS}${STRD} mirrors"; fi    
  
  # $1 is mode (normal || country)
  # $2 is the new pacman mirrorlist
  # $3 is the preferred country
  case "$1" in
    "normal")
      # copy new mirrorlist to a temp list
      cp "$2" "${PAC_LIST_TMP}"
      start_spinner "Ranking \"${GRN}${PAC_LIST_TMP}${STRD}\" ..."
      sleep 2
      # uncomment all servers
      sed -i 's/^#Server/Server/' "${PAC_LIST_TMP}"
      # rank mirrors with INPUT_MIRRORS number of mirrors, and replace
      # pacman mirrorlist with the newly ranked one
      rankmirrors -n "${INPUT_MIRRORS}" "${PAC_LIST_TMP}" > "${PAC_LIST_}"
    ;;
    "existing")
      # copy existing mirrorlist to a temp list
      cp "${PAC_LIST_}" "${PAC_LIST_TMP}"
      start_spinner "Ranking \"${GRN}${PAC_LIST_TMP}${STRD}\" ..."
      sleep 2
      # uncomment all servers
      sed -i 's/^#Server/Server/' "${PAC_LIST_TMP}"
      # rank mirrors with INPUT_MIRRORS number of mirrors, and replace
      # pacman mirrorlist with the newly ranked one
      rankmirrors -n "${INPUT_MIRRORS}" "${PAC_LIST_TMP}" > "${PAC_LIST_}"
    ;;
    "country")
      # copy new mirrorlist to a temp list
      cp "$2" "${PAC_LIST_TMP}"
      start_spinner "Ranking \"${GRN}${PAC_LIST_TMP}${STRD}\" based on [${GRN}$3${STRD}] ..."
      sleep 2
      # uncomment servers
      sed -i 's/^#Server/Server/' "${PAC_LIST_TMP}"
      # rank servers
      rankmirrors -n "$3" "${PAC_LIST_TMP}" > "$2"
    ;;
  esac
  
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

# Responsible for downloading mirrorlists and handling other options.
function get_list() {
  
  local LIST
  local CHOOSEN_COUNTRY
  local HTTP_CODE
  local URL
  local ISO_CODE
  
  declare -a AVAILABLE_OPTIONS
  
  case "$1" in
    "ipv4") LIST="${IPV4_LIST}" ;;
    "ipv6") LIST="${IPV6_LIST}" ;;
  esac
  
  # if get_list "ipvx"
  if [[ -z "$2" && -z "$3" ]]; then
    start_spinner "Checking \"${GRN}${LIST}${STRD}\" ..."
    sleep 2
    # get HTTP code
    HTTP_CODE=$(wget --spider -t 1 --timeout=10 -S "${LIST}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
    # if HTTP CODE is 200
    if [[ "${HTTP_CODE}" = 200 ]]; then
      stop_spinner $?
      clear_line
      start_spinner "Downloading new mirrorlist ..."
      sleep 2
      # download mirrorlist
      wget -q -O "${PAC_LIST_NEW}" "${LIST}"
      stop_spinner $?
      clear_line
      echo -e "Saved as \"${GRN}${PAC_LIST_NEW}${STRD}\""
    else
      stop_spinner $?
      clear_line
      echo -e "${RED}Server has connection issues, it may be down.${STRD}"
    fi
  # if get_list "ipvx" "rank"
  elif [[ -z "$3" ]]; then
    start_spinner "Checking \"${GRN}${LIST}${STRD}\" ..."
    sleep 2
    # get HTTP code
    HTTP_CODE=$(wget --spider -t 1 --timeout=10 -S "${LIST}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
    # if HTTP CODE is 200
    if [[ "${HTTP_CODE}" = 200 ]]; then
      start_spinner "Downloading new mirrorlist ..."
      sleep 2
      # download mirrorlist
      wget -q -O "${PAC_LIST_NEW}" "${LIST}"
      stop_spinner $?
      clear_line
      echo -e "Saved as \"${GRN}${PAC_LIST_NEW}${STRD}\""
      update_mirrors_count "${PAC_LIST_NEW}"
      echo -e "${ORNG}${MIRRORS_FOUND}${STRD} mirrors found"
      rank_mirrors "normal" "${PAC_LIST_NEW}"
    else
      stop_spinner $?
      clear_line
      echo -e "${RED}Server has connection issues, it may be down.${STRD}"
    fi
  # if get_list "ipvx" "rank" "country"
  else
    start_spinner "Checking \"${GRN}${ARCH_MIRRORLIST}${STRD}\" ..."
    sleep 2
    # get HTTP code from ARCH_MIRRORLIST
    HTTP_CODE=$(wget --spider -t 1 --timeout=10 -S "${ARCH_MIRRORLIST}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1)
    # if HTTP CODE is 200
    if [[ "${HTTP_CODE}" = 200 ]]; then
      stop_spinner $?
      clear_line
      start_spinner "Downloading \"${GRN}${ARCH_MIRRORLIST}${STRD}\" ..."
      sleep 2
      # download html to parse
      wget --quiet "${ARCH_MIRRORLIST}" -O "${PAC_LIST_TMP}"
      stop_spinner $?
      clear_line
      # extract values between "option" HTML tags
      grep -oP '(?<=<option value="[A-Z][A-Z]">).*(?=</option)' "${PAC_LIST_TMP}" > "${PAC_LIST_TMP_TWO}"
      # pass values into array
      AVAILABLE_OPTIONS=($(<"${PAC_LIST_TMP_TWO}"))
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
      # normalize value for future checking
      RETURNED_VALUE="0"
      # find country ISO code
      init_matching_country_array
      ISO_CODE="${MATCHING_COUNTRIES[${CHOOSEN_COUNTRY}]}"
      # assemble URL parts
      if [[ "$1" == "ipv4" ]]; then
        URL="${COUNTRY_LIST}${ISO_CODE}${COUNTRY_IPV4_PART}"
      elif [[ "$1" == "ipv6" ]]; then
        URL="${COUNTRY_LIST}${ISO_CODE}${COUNTRY_IPV6_PART}"
      fi
      # download only the prefered part
      wget --quiet "${URL}" -O "${PAC_LIST_TMP}" 
      # find how many mirrors exists for selected option (commented or not)
      update_mirrors_count "${PAC_LIST_TMP}"
      echo -e "${ORNG}${MIRRORS_FOUND}${STRD} mirrors found for [${GRN}${CHOOSEN_COUNTRY}${STRD}]"
      # copy modified mirrorlist to the existing one 
      cp "${PAC_LIST_TMP}" "${PAC_LIST_}"
      # rank mirrors
      rank_mirrors "country" "${PAC_LIST_}" "${CHOOSEN_COUNTRY}"
    # if HTTP CODE is not 200
    else
      stop_spinner $?
      clear_line
      echo -e "${RED}Server has connection issues, it may be down.${STRD}"
    fi
  fi
}

# Ranks mirrorlist.pacnew by country or not.
function rank_new() {
  
  case "$1" in
    "normal") 
      update_mirrors_count "${PAC_LIST_NEW}"
      echo -e "${ORNG}${MIRRORS_FOUND}${STRD} mirrors found"
      rank_mirrors "normal" "${PAC_LIST_NEW}"
    ;;
    "country") 
      #
      # NEEDS TO BE FIXED!!!!!
      # TODO
      # FIX IT SENPAI!!!!!
      #
      echo -e "${RED}Gomenasai, user-san! ${ORNG}xtonousou${RED} should fix this on new versions.${STRD}"
      echo -ne "${RED}Check line ${BLUE}${LINENO} "
      echo -e "${RED}on function ${ORNG}rank_new${STRD}(\"country\")"
      #update_mirrors_count "${PAC_LIST_NEW}"
      #echo -e "${ORNG}${MIRRORS_FOUND}${STRD} mirrors found"
      #rank_mirrors "country" "${PAC_LIST_NEW}"
    ;;
  esac
}

# Ranks existing /etc/pacman.d/mirrorlist.
function rank_existing() {
  
  local CHOOSEN_COUNTRY
  
  declare -a AVAILABLE_OPTIONS
  
  case "$1" in
    "normal")
      # if /etc/pacman.d/mirrorlist exists then rank it
      # else print error
      if [[ -f "${PAC_LIST_}" ]]; then
        update_mirrors_count "${PAC_LIST_}"
        echo -e "${ORNG}${MIRRORS_FOUND}${STRD} mirrors founds"
        rank_mirrors "existing" "${MIRRORS_FOUND}"
      else
        echo -e "${RED}Cannot find mirrorlist in ${PAC_DIR}${STRD}"
      fi
    ;;
    "country")
      #
      # NEEDS TO BE FIXED!!!!!
      # TODO
      # FIX IT SENPAI!!!!!
      #
      echo -e "${RED}Gomenasai, user-san! ${ORNG}xtonousou${RED} should fix this on new versions.${STRD}"
      echo -ne "${RED}Check line ${BLUE}${LINENO} "
      echo -e "${RED}on function ${ORNG}rank_new${STRD}(\"country\")"
      #update_mirrors_count "${PAC_LIST_NEW}"
      #echo -e "${ORNG}${MIRRORS_FOUND}${STRD} mirrors found"
      #rank_mirrors "country" "${PAC_LIST_NEW}"
      #if [[ -f "${PAC_LIST_}" ]]; then
      #  # make a copy of the current mirrolist
      #  cp "${PAC_LIST_}" "${PAC_LIST_TMP}"
      #  # if "Arch Linux repository mirrorlist" exists somewhere in mirrorlist, 
      #  # it means that mirrorlist is new or it is not yet parsed by madubi
      #  grep -i "Arch Linux repository mirrorlist" "${PAC_LIST_TMP}" > /dev/null 2>&1 && \
      #  sed -i '1,4d' "${PAC_LIST_TMP}" # if true, remove first four lines
      #  # keep only lines starting with double hashtag
      #  sed -n -i 's/^## //p' "${PAC_LIST_TMP}"
      #  # pass values from file to array
      #  AVAILABLE_OPTIONS=($(<"${PAC_LIST_TMP}"))
      #  # if options are available, print them out
      #  if [[ "${#AVAILABLE_OPTIONS[@]}" -ge 1 ]]; then
      #    for i in "${!AVAILABLE_OPTIONS[@]}"; do
      #      echo -ne "[${GRN}${AVAILABLE_OPTIONS[i]}${STRD}] "
      #    done
      #    echo
      #  while ! [[ "${RETURNED_VALUE}" -eq 1 ]]; do
      #      # read input
      #      read -p "Enter country: " -r CHOOSEN_COUNTRY
      #      # convert to lowercase
      #      CHOOSEN_COUNTRY=$(awk '{print tolower($0)}' <<< "${CHOOSEN_COUNTRY}")
      #      # capitalize first letter
      #      CHOOSEN_COUNTRY=$(sed -e "s/\b\(.\)/\u\1/g" <<< "${CHOOSEN_COUNTRY}")
      #      # validate input check if it exists in array
      #      check_if_in_array "${CHOOSEN_COUNTRY}" "${AVAILABLE_OPTIONS[@]}"
      #      RETURNED_VALUE="$?"
      #    done
      #    # normalize value for future checking
      #    RETURNED_VALUE="0"
      #    # extract only the prefered part
      #    awk "/${CHOOSEN_COUNTRY}/,/^$/" "${PAC_LIST_}" > "${PAC_LIST_TMP}" 
      #    # find how many mirrors exists for selected option (commented or not)
      #    #NUMBER_OF_MIRRORS=$(awk -v COUNT=0 "/^#Server/||/^Server/{COUNT++}END{print COUNT}" "${PAC_LIST_TMP}")
      #    update_mirrors_count "${PAC_LIST_TMP}"
      #    echo -e "${ORNG}${MIRRORS_FOUND}${STRD} mirrors found for [${GRN}${CHOOSEN_COUNTRY}${STRD}]"
      #    # copy modified mirrorlist to the existing one 
      #    cp "${PAC_LIST_TMP}" "${PAC_LIST_}"
      #    # rank mirrors
      #    rank_mirrors "country" "${MIRRORS_FOUND}" "${CHOOSEN_COUNTRY}"
      #  else
      #    echo -e "${RED}error${STRD}: \"${GRN}${PAC_LIST_}${STRD}\" does not contain any server."    
      #  fi
      #else
      #  echo -e "${RED}Cannot find mirrorlist in ${PAC_DIR}${STRD}"
      #fi
      #;;
  esac
}

# Outputs mirrors and their response times.
function show_info() {
  
  local FILE
  
  FILE="${PAC_DIR}/info.tmp"
  
  start_spinner "Querying servers. This may take some time ..."
  sleep 2
  rankmirrors -t "${PAC_LIST_}" > "${FILE}"
  stop_spinner $?
  clear
  echo -e "Values are in ${RED}seconds${STRD}"
  echo
  awk 'NR > 2 {print}' "${FILE}" | \
  grep --color -E "[0-9].*|unreachable|timeout"
  reset_screen
}

# Initializes the script.
function init() {
  
  # if "DEBUG" is on, ignore traps and checking functions
  if [[ "${DEBUG}" -eq 0 ]]; then
    trap trap_handler INT
    trap trap_handler SIGTSTP
    check_pacman
    check_rankmirrors
    check_permissions
    check_bash_version
    intro
  fi
  
  # print out the main_menu
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
