#!/bin/bash

function usage {
   echo -en "Usage: $0 host port mode [options]
  host can be string or ip address
  port 0-65535 (default is 5000)
  mode can be connect,gcode
  options are necessary only sometimes:
  - connect <dev/AUTO> <baudrate/AUTO>
  - gcode <gcode>
  - upload <file>
  - print <file>
  "
  exit 1 
}

function send_request {
  curl --data "$1" -H "Content-Type: application/json" http://$arg_host:$arg_port/ajax/$2 >& /dev/null

  case $? in

7)
  echo "Couldn't connect to host, check host and port"
;;

esac

}


if [ $# -lt 3 ];then
  usage
fi

arg_host=$1
arg_port=$2
arg_mode=$3


case $arg_mode in

connect)
  echo "Not yet implemented"
;;

gcode)
  if [ $# -lt 4 ]; then
    # gcode requires one more argument
    usage
  fi
  arg_gcode=$4
  send_request "{\"command\":\"$arg_gcode\"}" "control/command"
;;

upload)
  if [ $# -lt 4 ]; then
    # upload requires one more argument
    usage
  fi
  arg_file=$4

  echo "Not yet implemented"
;;

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
