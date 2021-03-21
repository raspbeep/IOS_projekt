#!/bin/sh

export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

# LIST OF VARIABLES
date_time_after=""
date_time_before="9999-12-31 24:60:59"
ticker=""
filter=0
after_dt=""
before_dt=""
ticker=""
width=-1
COMMANDS=""
LOG_FILES=""
GZ_LOG_FILES=""
LOGS=""

help() {
	echo "Usage: [do sth]"
}
launch_command() {
  for command in $COMMANDS; do
    case "$command" in list-tick)
      list_tick;;
    esac
    case "$command" in profit)
      profit;;
    esac
  done

}

list_tick() {
  echo "$LOGS" | awk -F ';' '{ print $2 }' | sort -u
}

profit() {
  buy_value=`echo "$LOGS" | awk -F ';' '$3 ~ /buy/ {sum += $4*$6} END {OFMT="%.2f";print sum}'`
  sell_value=`echo "$LOGS" | awk -F ';' '$3 ~ /sell/ {sum += $4*$6} END {OFMT="%.2f";print sum}'`
  echo "`echo "$sell_value - $buy_value" | bc`"
}

filter_logs() {
  IFS='\n'
  if [ $filter -ne 0 ]; then
    if [ -n "$tickers" ]; then
      LOGS=`echo $LOGS | grep "$tickers"`
    fi
    if [ -n "$date_time_after" ]; then
      LOGS=`echo $LOGS | awk -F ';' -v a="$date_time_after" '$1 > a {print \$0}'`
    fi
    if [ -n "$date_time_before" ]; then
      echo "$date_time_before"
      LOGS=`echo $LOGS | awk -F ';' -v b="$date_time_before" '$1 < b {print \$0}'`
    fi
  fi
}

hint() { echo "Usage tradelog [-h|--help] [FILTR] [PŘÍKAZ] [LOG [LOG2 [...]]" 1>&2; exit 1;}

if [ "$1" = "--help" ]; then
    help
    shift
else
  while [ "$#" -gt 0 ]; do
    case "$1" in list-tick | profit | pos | last-price | hist-ord | graph-pos)
      COMMANDS="$1";
      shift;
      ;;
    -h) 
      help
      exit 0
      ;;
    -a)
      date_time_after="$2"
      filter=1
      shift
      shift
      ;;
    -b)
      date_time_before="$2"
      filter=1
      shift
      shift
      ;;
    -t)
      if [ -z $tickers ]; then
        tickers="$2"
      else
        tickers="$tickers\|$2"
      fi
      filter=1
      shift
      shift
      ;;
    -w) width="$2"
      shift
      shift
      ;;
    *)
      if [ `echo $1 | grep "\.gz"` ]; then
        if [ -z "$LOGS" ]; then
          LOGS="`gzip -d -c $1`"
        else  
          LOGS="$LOGS\n`gzip -d -c $1`"
        fi
      elif [ `echo $1 | grep "\.log"` ]; then
        if [ -z "$LOGS" ]; then
          LOGS="`cat $1`"
        else
          LOGS="$LOGS\n`cat $1`"
        fi
      else
        echo "Invalid file" >&2
        exit 3
      fi
      shift
    esac
  done
fi

filter_logs
launch_command
echo "$LOGS"
# TICK_FILTER="grep '^.*;\($tickers\)'""
# READ_FILTERED="eval $READ_INPUT | awk -F ';' 'if (\$1 > $after_dt &&) {print \$0}' | eval "$TICK_FILTER""