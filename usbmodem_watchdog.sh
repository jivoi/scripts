#!/bin/bash

# yum install usb_modeswitch usb_modeswitch-data
# */5 * * * * /usr/local/bin/usbmodem_watchdog -m Huawei -s ya.ru -i wwp6s0u2i1 -n 3 -d 1-1 > /dev/null 2>&1


export PATH="$PATH:/usr/sbin"
SN="$(basename "$0")"

function print_help() {
    printf "\n"
    printf "Использование: %s options...\n" "$SN"
    printf "Параметры:\n"
    printf "  -s         Проверяемый ресурс.\n"
    printf "  -i         Имя сетевого интерфейса.\n"
    printf "  -d         Шина и порт модема lsusb -t.\n"
    printf "  -n         Число ошибочных пингов.\n"
    printf "  -m         Маркер модема, из команды lsusb.\n"
    printf "  -h         Справка.\n"
    printf "\n"
}

# Если скрипт запущен без аргументов, открываем справку.
if [[ $# = 0 ]]; then
    print_help && exit 1
fi
while getopts ":s:i:d:n:m:h" opt ;
do
    case $opt in
        s) SITE=$OPTARG;
            ;;
        i) IF=$OPTARG;
            ;;
        d) DEV=$OPTARG;
            ;;
        n) EP=$OPTARG;
            ;;
        m) MM=$OPTARG;
            ;;
        h) print_help
            exit 1
            ;;
        *) printf "Неправильный параметр\n";
           printf "Для вызова справки запустите %s -h\n" "$SN";
            exit 1
            ;;
        esac
done

if [[ "$SITE" == "" ]] || [[ "$IF" == "" ]] || [[ "$DEV" == "" ]] || [[ "$EP" == "" ]] || [[ "$MM" == "" ]] ;  then
 printf "\n"
 printf "Одна или несколько опций не указаны.\n"
 printf "Для справки наберите: %s -h\n" "$SN"
 printf "\n"
 exit 1
fi

M="$(lsusb | grep -w "$MM")"  #строка модема из lsusb


if [[ "$M" != "" ]]; then   #если модем выбран, можно проверять пинги

  if grep -w -q "$IF" /proc/net/dev; then #проверяем наличие сетевого интерфейса
   printf "\n"
   printf "Проверка доступности %s через интерфейс %s\n" "$SITE" "$IF"
   printf "\n"
    if [[ "$EP" -ge 6 ]]; then
     printf "Число ошибочных пингов должно быть меньше или равно 5\n"
     exit 1
    else
     printf "Делаем пинги...\n"
     flag="0"
     for i in {1..5}; do #делаем 5 пингов до сервера
     timeout -k 2 -s TERM 16 ping -w 14 -s 8 -c 1 -I "$IF" "$SITE" || flag=$((flag+1)) && printf "пинг:%s/5 (ошибок:%s)\n" "$i" "$flag" #пинг не прошел - инкрементируем счетчик
      if (("$flag" >= "$EP")); then
       break
      else
       read -r -t 1 > /dev/null
      fi
     done
     printf "потерь пакетов: %s из %s\n" "$flag" "$i"
     printf "\n"

     if (("$flag" >= "$EP")); then #если потерь пакетов больше 2х
      M="$(lsusb | grep "$MM")"   #на всякий случай снова глянем - вдруг модем выдернули
      printf "Будет сброшен модем:\n"
      printf "%s\n" "$M" | cut -c 34-
      if ! [[ -d /sys/bus/usb/drivers/usb/"$DEV" ]]; then
       printf "Неверно указаны Bus и Port модема.\n"
       exit 1
      else
      ifdown "$IF" #деактивируем интерфейс
      printf "%s" "$DEV" > "/sys/bus/usb/drivers/usb/unbind" && printf "%s" "$DEV" > "/sys/bus/usb/drivers/usb/bind" #перезегрузка модема
#      read -r -t 1 > /dev/null
      ifup "$IF" #активируем интерфейс
      fi
     fi
    fi
  else
   printf "\n"
   printf "Интерфейс %s не существует\n" "$IF"
   printf "\n"
   exit 1
  fi
else
  printf "Модем %s не найден.\n" "$MM"
fi