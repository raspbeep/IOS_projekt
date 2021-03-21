#!/bin/sh

export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

# LIST OF VARIABLES
#date_time_after=""
#date_time_before=""
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
  buy_value=0
  sell_value=0
  profit_value=0
  IFS='\n'

  while IFS= read -r line
    do
    unit_price=`echo "$line" | awk -F ';' '{print $4}'`
    volume=`echo "$line" | awk -F ';' '{print $6}'`
    total=`echo $unit_price\*$volume | bc`
    if [ `echo $line | grep "buy"` ]; then
      buy_value=`echo "$buy_value + $total" | bc`
    else
      sell_value=`echo "$sell_value + $total" | bc`
    fi
  done <<< $LOGS
  profit_value=`echo "$sell_value - $buy_value" | bc`
  echo "$profit_value"
}

filter_logs() {
  if [ $filter -ne 0 ]; then
    if [ -n "$tickers" ]; then
      NEW_LOGS=""
      IFS='\n'

      while IFS= read -r line
      do
        found_ticker=0
        IFS=' '
        for ticker in $tickers; do
          if [ "`echo $line | grep "$ticker"`" ]; then
            found_ticker=1
          fi
        done
        if [ $found_ticker -gt 0 ]; then
          if [ "$NEW_LOGS" ]; then
            NEW_LOGS="$NEW_LOGS\n$line"
          else
            NEW_LOGS="$line"
          fi
        fi
        IFS='\n'
      done <<< $LOGS
      
      LOGS=$NEW_LOGS
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
      after_dt="$2"
      filter=1
      shift
      shift
      ;;
    -b)
      before_dt="$2"
      filter=1
      shift
      shift
      ;;
    -t)
      if [ -z $tickers ]; then
        tickers="$2"
      else
        tickers="$tickers $2"
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
echo "$LOGS"
launch_command

# TICK_FILTER="grep '^.*;\($tickers\)'""
# READ_FILTERED="eval $READ_INPUT | awk -F ';' 'if (\$1 > $after_dt &&) {print \$0}' | eval "$TICK_FILTER""