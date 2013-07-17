#!/bin/bash

function usage {
   echo -en "Usage: $0 host port mode [options]
  host can be string or ip address
  port 0-65535 (default is 5000)
  mode can be connect,gcode
  options are necessary only sometimes:
  - connect <dev/VIRTUAL/AUTO> <baudrate/AUTO>
  - gcode <gcode>
  - upload <file>
  - print <file>
  "
  exit 1 
}

function handle_curl_retval {
  case $1 in
    7)
      echo "Couldn't connect to host, check host and port"
    ;;
  esac
}

function send_json_request {
  curl --data "$1" -H "Content-Type: application/json" http://$arg_host:$arg_port/ajax/$2
  handle_curl_retval $?
}

function send_urlencoded_request {
  curl "http://$arg_host:$arg_port/ajax/control/connection" -H "Content-Type: application/x-www-form-urlencoded"  --data $1
  handle_curl_retval $?
}


if [ $# -lt 3 ];then
  usage
fi

arg_host=$1
arg_port=$2
arg_mode=$3

case $arg_mode in


#############################################################
##                                                         ##
##  CONNECT                                                ##
##                                                         ##
#############################################################
connect)
  if [ $# -lt 4 ]; then
    # upload requires one more argument
    usage
  fi
  arg_dev=$4
  arg_baud=$5
  send_urlencoded_request "command=connect&port=$arg_dev&baudrate=$arg_baud"
  
;;

#############################################################
##                                                         ##
##  DISCONNECT                                             ##
##                                                         ##
#############################################################
disconnect)
  send_urlencoded_request "command=disconnect"
  
;;

#############################################################
##                                                         ##
##  GCODE                                                  ##
##                                                         ##
#############################################################
gcode)
  if [ $# -lt 4 ]; then
    # gcode requires one more argument
    usage
  fi
  arg_gcode=$4
  send_json_request "{\"command\":\"$arg_gcode\"}" "control/command"
;;

#############################################################
##                                                         ##
##  UPLOAD                                                 ##
##                                                         ##
#############################################################
upload)
  if [ $# -lt 4 ]; then
    # upload requires one more argument
    usage
  fi
  arg_file=$4
  filename=$(basename "$arg_file")
  extension="${filename##*.}"
  filename="${filename%.*}"
  
  if [[ $extension != gcode ]] && [[ $extension != g ]];then
    echo "WARNING: You should name files like \"$filename.gcode\" or \"$filename.g\""
  fi
  
  curl "http://$arg_host:$arg_port/ajax/gcodefiles/upload"  -F gcode_file=@"$arg_file" >& /dev/null
  
  if [[ $? == 26 ]];then
    echo "ERROR: Couldn't open file $arg_file"
    exit 26
  fi
;;

#############################################################
##                                                         ##
##  PRINT                                                  ##
##                                                         ##
#############################################################
print)
  if [ $# -lt 4 ]; then
    # print requires one more argument
    usage
  fi
  arg_file=$4

  echo "Not yet implemented"
;;


*)
usage
;;

esac
