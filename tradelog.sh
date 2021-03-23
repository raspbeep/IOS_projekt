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
set_width=0
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
    case "$command" in pos)
      pos;;
    esac
    case "$command" in last-price)
      last_price;;
    esac
    case "$command" in hist-ord)
      hist_ord;;
    esac
    case "$command" in graph-pos)
      graph_pos;;
    esac
  done

}

list_tick() {
  echo "$LOGS" | awk -F ';' '{ print $2 }' | sort -u
}

profit() {
  buy_value=""
  sell_value=""
  buy_value=`echo "$LOGS" | awk -F ';' '$3 ~ /buy/ {sum += $4*$6} END {OFMT="%.2f";print sum}'`
  sell_value=`echo "$LOGS" | awk -F ';' '$3 ~ /sell/ {sum += $4*$6} END {OFMT="%.2f";print sum}'`
  if [ -n "$buy_value" ] && [ -n "$sell_value" ]; then 
    echo "`echo "$sell_value - $buy_value" | bc`"
  else
    echo "empty selection"
  fi
}

hist_ord() {
  if [ $width -eq -1 ]; then
    echo "$LOGS" | awk -F ';' '
      BEGIN{}
      {
        transaction_counter[$2]++;
      }
      END{
        for (i in transaction_counter) {
          printf "%-10s: ", i;
          for (counter=0; counter < transaction_counter[i]; counter++) {
            printf "#";
          }
          printf "\n";
        }
      }' | sort
  fi
}

graph_pos() {
  if [ $width -eq -1 ]; then
    echo "$LOGS" | awk -F ';' -v width="$width" '
    BEGIN{}
    {
      dic_last_prices[$2]=$4;
    }
    {
      if ($3 == "buy") {
        number_of_shares[$2]+=$6;
      } else {
        number_of_shares[$2]-=$6;
      }
    }
    END{
      max_length=0;
      for (i in dic_last_prices) {
        total_value=dic_last_prices[i]*number_of_shares[i]

        if (length(total_value) > max_length){
          max_length=length(total_value);
        }
      }
      for (i in dic_last_prices) {
        total_value=dic_last_prices[i]*number_of_shares[i]
        printf "%-10s: %.2f\n", i, total_value;
      }
    }' | sort -k3 -nr
  fi
}


last_price() {
  echo "$LOGS" | awk -F ';' '
  BEGIN{}
  {
    dic_last_prices[$2]=$4;
  }
  END{
    for (i in dic_last_prices) {
      printf "%-10s: %.2f\n", i, dic_last_prices[i]
    }
  }' | sort
}

pos() {
  echo "$LOGS" | awk -F ';' '
  BEGIN{}
  {
    dic_last_prices[$2]=$4;
  }
  {
    if ($3 == "buy") {
      number_of_shares[$2]+=$6;
    } else {
      number_of_shares[$2]-=$6;
    }
  }
  END{
    max_length=0;
    for (i in dic_last_prices) {
      total_value=dic_last_prices[i]*number_of_shares[i]

      if (length(total_value) > max_length){
        max_length=length(total_value);
      }
    }
    for (i in dic_last_prices) {
      total_value=dic_last_prices[i]*number_of_shares[i]
      printf "%-10s: %.2f\n", i, total_value;
    }
  }' | sort -k3 -nr
  # remove spaces gsub(/ /, "", premenna)
  # stanoveny pocet medzier %*c , 5, " "
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
    if [ "$date_time_before" != "9999-12-31 24:60:59" ]; then
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
      echo "hmm"
      date_time_after="$2 $3"
      filter=1
      shift
      shift
      shift
      ;;
    -b)
      date_time_before="$2 $3"
      filter=1
      shift
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
      if [ $set_width -ne 0 ]; then
        exit 1
      fi
      set_width=1
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
        #echo "Invalid file" >&2
        exit 1
      fi
      shift
    esac
  done
fi

filter_logs
launch_command
#echo "$LOGS"
# TICK_FILTER="grep '^.*;\($tickers\)'""
# READ_FILTERED="eval $READ_INPUT | awk -F ';' 'if (\$1 > $after_dt &&) {print \$0}' | eval "$TICK_FILTER""