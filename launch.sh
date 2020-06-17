#!/bin/sh
#
# appi.sh: Easy applications via a 1-line command
#
# Uses common utilities to perform tasks usually dependent on heavier apps
#
#
# License: The Unlicense, https://unlicense.org
#
# Usage: execute this script from remote script or the project root
#
#     run from internet:
#
#     $   sh <(curl -sSl https://appi.sh/launch)
#
#     run locally:
#
#     $   sh launch.sh
#

main_menu() {
  clear
  echo ""
  echo "====================================="
  echo "  appi.sh: launchpad"
  echo "====================================="
  echo ""
  echo "c) Convert dynamic site to static"
  echo ""
  echo "q) Quit this menu"
  echo ""
  echo ""
  echo "Please type (c) or (q) and the Enter key: "
  echo ""
  read -r main_menu_choice

  if [ "$main_menu_choice" != "${main_menu_choice#[cq]}" ] ;then
    case $main_menu_choice in
      c|C) convert_site_source_url_input ;;
      q|Q) exit 0 ;;
    esac

  else
    main_menu
  fi
}

download_source_site() {
  # do hostnames only replacement.
  # /foo forces dirname to return hostname if no segments, helping catch ports
  SOURCE_URL_HOST_PORT="$(basename "$( dirname "$SOURCE_URL/foo" )" )"
  DESTINATION_URL_HOST_PORT="$(basename "$( dirname "$DESTINATION_URL/foo" )" )"

  # strip all non-alpha characters from desturl, convert to lowercase
  OUTPUT_DIR_NAME="/tmp/$(echo "$DESTINATION_URL_HOST_PORT" | tr -cd '[:alnum:]-' | \
    tr '[:upper:]' '[:lower:]')/"

  echo "Downloading source site to $OUTPUT_DIR_NAME ..."

  # download site quitely (TODO: add option to log output)
  WGET_OUTPUT="$(wget -P "$OUTPUT_DIR_NAME" -nH -mpcbq --user-agent="Appi.sh" \
    -e robots=off --wait 1 -E "$SOURCE_URL" )"

  WGET_PID="$( echo "${WGET_OUTPUT}" | awk '/ pid / { print 0 + $(NF); }' )"

  # TODO: need to check site hasn't already finished downloading 
  echo "$WGET_PID"

  # while our wget is running, display progress
  while true
  do
    # shellcheck disable=SC2009
    # we know the PID and want to confirm name
    if [ "$(ps -p "$WGET_PID" | grep wget 2> /dev/null )" = "" ] ; then
      break
    else
      clear
      echo ""
      echo "====================================="
      echo "  appi.sh: launchpad"
      echo "====================================="
      echo ""
      echo ' Downloading your site....'

      # TODO: check for dir existence first

      FILES_SAVED="$( find "$OUTPUT_DIR_NAME" -type f | wc -l )"
      SAVED_SIZE="$( du -sh "$OUTPUT_DIR_NAME" )"

      echo " Downloaded $SAVED_SIZE in $FILES_SAVED files..."
      sleep 0.5
    fi
  done

  echo 'Downloading complete!'

  post_process_crawled_site
}

post_process_crawled_site() {
  echo 'Processing saved site...'
  cd "$OUTPUT_DIR_NAME" || exit 1

  # do straight source to destination replacement
  grep -Rl "$SOURCE_URL" . | xargs sed -i "s|$SOURCE_URL|$DESTINATION_URL|g"

  grep -Rl "$SOURCE_URL_HOST_PORT" . | xargs sed -i \
    "s|$SOURCE_URL_HOST_PORT|$DESTINATION_URL_HOST_PORT|g"

  # TODO: appease shellcheck
  for i in $(find . -type f)
  do
      mv "$i" "$(echo "$i" | cut -d? -f1)"
  done

  echo "Processing complete"
}

convert_site_destination_url_input() {
  clear
  echo ""
  echo "================================================"
  echo "      appi.sh: Static Site Converter         "
  echo "================================================"
  echo "   Press (Ctrl) and (c) keys to exit anytime    "
  echo "------------------------------------------------"
  echo ""
  echo "Enter the destination URL for converted website:"
  echo ""
  echo "ie, http://example.com"
  echo ""
  echo ""
  echo "Type/paste the site's URL, then the Enter key: "
  echo ""
  read -r destination_url_choice

  # convert to lowercase
  DESTINATION_URL="$(echo "$destination_url_choice" | tr '[:upper:]' '[:lower:]')"

  # check name is not empty
  if [ "$DESTINATION_URL" = "" ]; then
    convert_site_destination_url_input
  # check site is accessible
  else
   download_source_site
  fi
}

convert_site_source_url_input() {
  clear
  echo ""
  echo "================================================"
  echo "      appi.sh: Static Site Converter         "
  echo "================================================"
  echo "   Press (Ctrl) and (c) keys to exit anytime    "
  echo "------------------------------------------------"
  echo ""
  echo "Enter the URL of the website to convert:"
  echo ""
  echo "ie, http://localhost"
  echo ""
  echo ""
  echo "Type/paste the site's URL, then the Enter key: "
  echo ""
  read -r source_url_choice

  # convert to lowercase
  SOURCE_URL="$(echo "$source_url_choice" | tr '[:upper:]' '[:lower:]')"

  # check name is not empty
  if [ "$SOURCE_URL" = "" ]; then
    convert_site_source_url_input
  # check site is accessible
  else
    SOURCE_STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SOURCE_URL")

    if [ ! "$SOURCE_STATUS_CODE" = 200 ];then
      echo "Invalid response code from URL: $SOURCE_STATUS_CODE"
      sleep 1
      convert_site_source_url_input
    else
     convert_site_destination_url_input
    fi
  fi

}


main_menu

exit 0




