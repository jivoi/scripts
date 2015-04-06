#!/usr/bin/env python
import os
import urllib2
import pwd
import smtplib
import socket
import requests

hostname = socket.gethostname()
url = "http://localhost/http_check"
stop_file = '/tmp/check_stop'
user = 'www'
timeout = 300

mail_from = "adm@" + hostname
mail_to = "root@example.ru"

def mail(server_url=None, sender='', to='', subject='', text=''):
    if not to:
        return
    headers = "From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n" % (sender, to, subject)
    message = headers + text
    mail_server = smtplib.SMTP(server_url)
    mail_server.sendmail(sender, to, message)
    mail_server.quit()

def pkill(user):
    pids = []
    user_pids = []
    uid = pwd.getpwnam(user).pw_uid
    for i in os.listdir('/proc'):
        if i.isdigit():
            pids.append(i)
    for i in pids:
        puid = os.stat(os.path.join('/proc', i)).st_uid
        if puid == uid:
            user_pids.append(i)
    for i in user_pids:
        if os.path.exists(os.path.join('/proc',i)):
            try:
                os.kill(int(i), 15)
            except OSError as e:
                print e
                #exit(0)

def check_http(url):
    try:
        response = requests.get(url, timeout=timeout)
        response.close()
    except (ConnectionError, HTTPError, Timeout ) as e:
            #mail('localhost', mail_from, mail_to, 'HttpCheck at ' + hostname, "kill all")
            pkill(user)

def main():
    if os.path.isfile(stop_file):
        sys.exit(0)
    else:
        check_http(url)

if __name__ == '__main__':
    main()
