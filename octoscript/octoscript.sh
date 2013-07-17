#!/bin/bash

function usage {
   echo -en "Usage: $0 host port mode [options]
  host can be string or ip address
  port 0-65535 (default is 5000)
  mode can be connect,gcode
  options are necessary only sometimes:
  - connect <dev/VIRTUAL/AUTO> <baudrate/AUTO>
  - gcode <gcode>: send <gcode> to the printer
  - upload <file>: upload <file> to octoprint
  - delete <file>: <file> will be removed
  - list:          list uploaded files
  - print <file>:  load and start <file> printing
  - load <file>:   load <file> but don't start printing
  - start:         start printing of already loaded file. If none is loaded, don't do anything. If print is paused, restart.

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
  curl --data "$1" -H "Content-Type: application/json" http://$arg_host:$arg_port/ajax/$2 >& /dev/null
  handle_curl_retval $?
}

function send_urlencoded_request {
  curl "http://$arg_host:$arg_port/ajax/control/connection" -H "Content-Type: application/x-www-form-urlencoded"  --data $1 >& /dev/null
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
##  DELETE                                                 ##
##                                                         ##
#############################################################
delete)
  if [ $# -lt 4 ]; then
    # upload requires one more argument
    usage
  fi
  arg_file=$4

  curl "http://$arg_host:$arg_port/ajax/gcodefiles/delete" -H "Content-Type: application/x-www-form-urlencoded"  --data "filename=$arg_file" >& /dev/null

;;

#############################################################
##                                                         ##
##  LIST                                                   ##
##                                                         ##
#############################################################

list)

  curl "http://$arg_host:$arg_port/ajax/gcodefiles" 2> /dev/null | grep name|sed 's/.*: "// ; s/",//'

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

  # Load
  curl "http://$arg_host:$arg_port/ajax/gcodefiles/load" -H "Content-Type: application/x-www-form-urlencoded"  --data "filename=$arg_file&print=true" >& /dev/null
  
;;

#############################################################
##                                                         ##
##  LOAD                                                  ##
##                                                         ##
#############################################################
load)
  if [ $# -lt 4 ]; then
    # print requires one more argument
    usage
  fi
  arg_file=$4

  curl "http://$arg_host:$arg_port/ajax/gcodefiles/load" -H "Content-Type: application/x-www-form-urlencoded"  --data "filename=$arg_file&print=false" >& /dev/null
  
;;

#############################################################
##                                                         ##
##  START                                                  ##
##                                                         ##
#############################################################
start)

  curl "http://$arg_host:$arg_port/ajax/control/job" -H "Content-Type: application/x-www-form-urlencoded"  --data "command=start" >& /dev/null
  
;;



#############################################################
##                                                         ##
##  CANCEL                                                 ##
##                                                         ##
#############################################################

cancel)

  curl "http://$arg_host:$arg_port/ajax/control/job" -H "Content-Type: application/x-www-form-urlencoded"  --data "command=cancel" >& /dev/null

;;

#############################################################
##                                                         ##
##  PAUSE                                                  ##
##                                                         ##
#############################################################

pause)
  echo "INFO: To resume printing, just launch \"pause\" command again"
  curl "http://$arg_host:$arg_port/ajax/control/job" -H "Content-Type: application/x-www-form-urlencoded"  --data "command=pause" >& /dev/null

;;


*)
usage
;;

esac
