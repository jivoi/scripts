#BASH. Создание chroot окружения для SSH chroot в FreeBSD. 
#!/usr/local/bin/bash

# Проверка задано ли имя пользователя
if [ "$1" = "" ] ; then
  echo "    Usage: $0 [ username ]"
  exit
fi


USER=$1
GID=`cat /etc/master.passwd | grep "^$USER:" | cut -d ":" -f 4`
HOMEDIR=/home/$USER

# Задаем список бинарных файлов, 
# которые хотим предоставить пользователю
BINARIES="
/bin/cat \
/bin/chmod \
/bin/cp \
/bin/csh \
/bin/date \
/bin/echo \
/bin/expr \
/bin/ln \
/bin/ls \
/bin/mkdir \
/bin/mv \
/bin/ps \
/bin/pwd \
/bin/rm \
/bin/rmdir \
/bin/sh \
/usr/bin/awk \
/usr/bin/bzip2 \
/usr/bin/diff \
/usr/bin/du \
/usr/bin/ee \
/usr/bin/fetch \
/usr/bin/find \
/usr/bin/grep \
/usr/bin/gunzip \
/usr/bin/gzip \
/usr/bin/less \
/usr/bin/sed \
/usr/bin/sort \
/usr/bin/tail \
/usr/bin/tar \
/usr/bin/touch \
/usr/bin/vi \
/usr/local/bin/bash \
/usr/local/bin/mc \
/usr/local/bin/mcedit \
/usr/local/bin/mcmfmt \
/usr/local/bin/unrar \
/usr/local/bin/unzip \
/usr/local/bin/wget"

# Создаем структуру каталогов внутри chroot окружения
mkdir $HOMEDIR/bin
mkdir $HOMEDIR/etc
mkdir $HOMEDIR/home
mkdir $HOMEDIR/home/$USER
mkdir $HOMEDIR/lib
mkdir $HOMEDIR/libexec
mkdir $HOMEDIR/tmp
mkdir $HOMEDIR/usr
mkdir $HOMEDIR/usr/bin
mkdir $HOMEDIR/usr/local
mkdir $HOMEDIR/usr/local/bin
mkdir $HOMEDIR/usr/local/etc
mkdir $HOMEDIR/usr/local/share

# Копируем бинарники внутрь chroot окружения
for item in $BINARIES;
do
  cp $item $HOMEDIR$item
done

# Определяем какие библиотеки необходимо скопировать
for item in $BINARIES;
do
  ldd $item |awk '{print $3}'|grep "."  >> /tmp/chroot_liblist
done

# Копируем библиотеки
for item in `cat /tmp/chroot_liblist|sort|uniq`;
do
  cp $item $HOMEDIR/lib/
done

# Копируем оставшиеся необходимые файлы и библиотеки
cp /etc/termcap $HOMEDIR/etc/termcap
cp /etc/resolv.conf $HOMEDIR/etc/resolv.conf
cp /etc/nsswitch.conf $HOMEDIR/etc/nsswitch.conf
cp -R /usr/local/share/mc $HOMEDIR/usr/local/share/mc
cp /libexec/ld-elf.so.1 $HOMEDIR/libexec/ld-elf.so.1
cp /libexec/ld-elf32.so.1 $HOMEDIR/libexec/ld-elf32.so.1

# Генерируем /etc/motd для chroot окружения
echo 'Welcome to chroot environment' > $HOMEDIR/etc/motd

# Генерируем /etc/profile для chroot окружения
echo 'export TERMCAP=/etc/termcap' > $HOMEDIR/etc/profile
echo 'export PS1="[ w ]$ "' >> $HOMEDIR/etc/profile

# Генерируем /etc/group для chroot окружения
cat /etc/group | grep $GID > $HOMEDIR/etc/group

# Переносим запись о пользователе
cat /etc/master.passwd|grep "^$USER:" > $HOMEDIR/etc/master.passwd
pwd_mkdb -d $HOMEDIR/etc $HOMEDIR/etc/master.passwd

# Выставляем права
chown root:wheel  $HOMEDIR
chmod 755 $HOMEDIR
chown -R $USER:$GID $HOMEDIR/bin
chown -R $USER:$GID $HOMEDIR/etc
chown -R $USER:$GID $HOMEDIR/home
chown -R $USER:$GID $HOMEDIR/lib
chown -R $USER:$GID $HOMEDIR/libexec
chown -R $USER:$GID $HOMEDIR/tmp
chown -R $USER:$GID $HOMEDIR/usr
chmod 777 $HOMEDIR/tmp

# Подчищаем за собой
rm /tmp/chroot_liblist