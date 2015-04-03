#!/bin/sh

FILE=`zenity --file-selection --directory --title="Выберите путь к крякозябрам"`
case $? in
0)
echo "Выбран \"$FILE\".";;
1)
echo "Файл не выбран.";;
-1)
echo "Файл не выбран.";;
esac 
cd "$FILE" || exit; 
(find -iname '*.mp3' -print0 | xargs -0 mid3iconv -e KOI8-R --remove-v1; find -iname '*.mp3' -print0 | xargs -0 mid3iconv -e CP1251 --remove-v1)|zenity --progress --pulsate --auto-close --text "идет процесс" --title "Меняем кодировку"
zenity --info --text="теперь у Вас православный UTF"
