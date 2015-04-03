#!/bin/sh
# Скрипт проверяет документы на обновления и шлёт диффы изменений на email
# Зависит от: wget, w3m, diff, md5sum, mail (sendmail)

DIR="$HOME/documents/"
EMAIL="user@example.com"

LIST="url1
url2
url3"

function test_ping() {
    if ! ping -q -c 3  $1; then
	echo "не пингуется $1"
	exit 1
    fi
}

ping_host="ya.ru"
test_ping $ping_host

for url in $LIST; do
    md5this=$(echo $url | md5sum | sed 's/\ .*$//')
    checkfile="$HOME/etc/.pagecheck.$md5this.md5"
    # Если нет $checkfile, значит страница проверяется первый раз
    if [ -f $checkfile ];
    then
	w3m -dump $url | md5sum | diff - $checkfile # Проверяем md5 на изменения
	if [ $? = 1 ]; then
	    echo "changed: $url"
	    w3m -dump $url | md5sum > $checkfile # обновляем md5 дампа
	    mv $HOME/etc/.pagecheck.$md5this.content $HOME/etc/.pagecheck.$md5this.content-old # Перемещаем дамп в резерв
	    w3m -dump $url > $HOME/etc/.pagecheck.$md5this.content # Скачиваем новый дамп
	    diff $HOME/etc/.pagecheck.$md5this.content $HOME/etc/.pagecheck.$md5this.content-old | mail -s "UPDATED: $url" $EMAIL # Делаем diff дампа и шлём на email
	    cd $DIR && wget -p $url # Скачиваем страничку
	fi
    else
	w3m -dump $url | md5sum > $checkfile # запоминаем md5sum для последующих проверок
	w3m -dump $url > $HOME/etc/.pagecheck.$md5this.content # Скачиваем дамп
	# Скачиваем страничку
	cd $DIR && wget -p $url
    fi
done;