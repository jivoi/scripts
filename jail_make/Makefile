#
# example:
#JAILS=		jail1:jail1.example.ru:10.10.10.6 \
#		jail2:jail2.dev.example.ru:10.10.10.4

JAILS=		jail1:jail1.example.ru:10.10.10.6

RO=		bin lib libexec sbin usr dev
RW=		root usr/local usr/build etc usr/home tmp var www

NFSMOUNTS=	/usr/src /usr/obj
CONFIGS=	fstab rc.config
INSTALLDIR=	/www/jail-struct
JAILDIR=	/www/jail
RCCONF=		/etc/rc.conf
ECHO_MSG?=	echo
MKDIR_PROG?=	mkdir -p

all:	clean conf

conf:
	@${ECHO_MSG} "=> Generating ${@}"
	@for JAIL in ${JAILS}; do \
		NAME=`echo $${JAIL} | cut -f1 -d:`; \
		HOSTNAME=`echo $${JAIL} | cut -f2 -d:`; \
		IP=`echo $${JAIL} | cut -f3 -d:`; \
		${ECHO_MSG} "==> $${HOSTNAME}" ; \
		for CONFIG in ${CONFIGS}; do \
		sed -e "s|%HOSTNAME%|$${HOSTNAME}|g" \
			-e "s|%NAME%|$${NAME}|g" -e "s|%IP%|$${IP}|g" $${CONFIG}.in > $${HOSTNAME}.$${CONFIG} ;\
		done ; \
	done

install: conf
	@for JAIL in ${JAILS}; do \
		NAME=`echo $${JAIL} | cut -f1 -d:` ; \
		HOSTNAME=`echo $${JAIL} | cut -f2 -d:` ; \
		if [ -f ${INSTALLDIR}/$${HOSTNAME}.fstab ]; then : ; \
		else  \
			${ECHO_MSG} "==> Installing fstab for $${HOSTNAME}" ; \
			cp $${HOSTNAME}.fstab /www/jail-struct/ ; \
		fi ; \
		if cat ${RCCONF} | grep -e "jail_$${NAME}_hostname=\"$${HOSTNAME}\"" > /dev/null ; then : ; \
		else \
			${ECHO_MSG} "==> Installing rc script for ${NAME}" ; \
			cat $${HOSTNAME}.rc.config >> /etc/rc.conf ; \
		fi ; \
		if cat ${RCCONF} | grep jail_list | grep -e " $${NAME}" -e "$${NAME} " > /dev/null ; then : ; \
		else \
			sed -i '' -e "s|jail_list=\"|jail_list=\"$${NAME} |g" ${RCCONF} ; \
			${ECHO_MSG} "==> Adding in jail_list $${NAME}" ; \
		fi ; \
	done

create: conf
	@${ECHO_MSG} "=> Creating jails"
	@for NFSMOUNT in ${NFSMOUNTS}; do \
		if mount | grep -e "$${NFSMOUNT}" > /dev/null ; then : ; \
		else \
			${ECHO_MSG} "==> Mounting $${NFSMOUNT} .." ; \
			mount $${NFSMOUNT} ; \
		fi ; \
	done
	@for JAIL in ${JAILS}; do \
		HOSTNAME=`echo $${JAIL} | cut -f2 -d:` ; \
		if [ -d ${JAILDIR}/$${HOSTNAME} -o -d ${INSTALLDIR}/$${HOSTNAME} ]; then \
			${ECHO_MSG} "==> $${HOSTNAME} already created! Skiping.." ; \
		else \
			${ECHO_MSG} "==> Making $${HOSTNAME}" ; \
			for DIR in ${RO} ${RW}; do \
				${ECHO_MSG} "===> Creating $${DIR}" ; \
				${MKDIR_PROG} ${INSTALLDIR}/$${HOSTNAME}/$${DIR} ${JAILDIR}/$${HOSTNAME}/$${DIR}; \
			done ; \
			cd /usr/src && make -s -i distrib-dirs DESTDIR=${INSTALLDIR}/$${HOSTNAME}; \
			cd /usr/src && make -s -i distribution DESTDIR=${INSTALLDIR}/$${HOSTNAME}; \
		fi ; \
	done

init:
	@${ECHO_MSG} "=> Starting init.."
	@if cat ${RCCONF} | grep jail_enable  > /dev/null ; then : ; \
	else \
		${ECHO_MSG} "jail_enable=\"YES\"" >> ${RCCONF} ; \
		${ECHO_MSG} "jail_sysvipc_allow=\"YES\"" >> ${RCCONF} ; \
		${ECHO_MSG} "jail_list=\"\"" >> ${RCCONF} ; \
	fi
	
clean:
	@${ECHO_MSG} "=> Cleaning.."
	@rm -f *~ *.fstab *.rc.config

help:
	@${ECHO_MSG} "Usage: init create conf install"
