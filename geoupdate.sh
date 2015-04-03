#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
DATE=`date "+%Y%m%d"`
URL="http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip"
DBNEW="maxmind.zip"
DBOLD="maxmind_last.zip"
GEODB="geo.conf"
DBDIR="./GEODB/"

dummy() {
	echo "Do nothing :)"
}

test_db() {
	wget -q -O ${DBNEW} ${URL}
    DBNEWSZ=$(stat -c%s "${DBNEW}")
    DBOLDSZ=$(stat -c%s "${DBOLD}")
	if [ ${DBNEWSZ} = ${DBOLDSZ} ]; then
    echo "DB IS UP-TO-DATE,NO NEED TO UPDATE"
	else 
    make_new_db
	fi
}

make_new_db() {
	#wget -q -O ${DBNEW} ${URL}
	unzip -o -qq ${DBNEW}
    ./geo2nginx.pl < GeoIPCountryWhois.csv > geo.conf

	grep -e "AZ\|AM\|BY\|GE\|KZ\|KG\|MD\|RU\|TJ\|UZ\|\TM\|EE\|LT\|LV" ${GEODB} |tr [A-Z] [a-z] > ${DBDIR}geo.ru
	grep UA ${GEODB} | tr [A-Z] [a-z] > ${DBDIR}geo.ua
	grep CN ${GEODB} | sed s/CN/1/g > ${DBDIR}denyexpress

	cp ${GEODB} ${DBDIR}geo_full.conf

	grep RU ${GEODB} | sed s/RU/0/g > ${DBDIR}russian.geo
	grep UA ${GEODB} | sed s/UA/2/g > ${DBDIR}ukraina-newline.geo

	cp ${GEODB} ${DBDIR}geo.conf

	grep CN ${GEODB} > ${DBDIR}china.geo
	grep ES ${GEODB} | sed s/ES/2/g > ${DBDIR}spain.geo

	grep UA ${GEODB} > ${DBDIR}geo_ua.conf

    cp ${DBNEW} ${DBOLD}
}

build_geo() {
	echo "Checkouting revision $REV"
}

build_nginx() {
	echo "Checkouting revision $REV"
}

restart() {
	echo "Checkouting revision $REV"
}

undo() {
	echo "Checkouting revision $REV"
}

case $1 in
	geoup)
	make_new_db
	#test_db
		;;
	install_geo)
        backup
        build_libs
		restart
		;;
	dummy)
		dummy
		;;
	*)
		echo "Use $0 (geoup|install_geo|)"
	;;
esac
