#!/usr/bin/env python
# -*- coding: utf8 -*-
import os,sys,platform,subprocess,smtplib,MySQLdb
from socket import gethostname

system = platform.system()
email_subject = "Replication problem on slave %s"
email_to = "root@example.ru"
email_from = " "
 
def mysql_cmd(cmd):
    cnx = MySQLdb.connect(user='root', host='localhost', connect_timeout=10)
    cur = cnx.cursor()
    cur.execute(cmd)
    columns = tuple( [d[0].decode('utf8') for d in cur.description] )
    row = cur.fetchone()
    if row is None:
        raise StandardError("MySQL Server not configured as Slave")
    result = dict(zip(columns, row))
    cur.close()
    cnx.close()
    return result
 
try:
    slave_status = mysql_cmd("show slave status")
except StandardError, msg:
    print >> sys.stderr, "There was an error:", msg
    sys.exit(1)
     
if (slave_status['Slave_IO_Running'] == 'Yes' and slave_status['Slave_SQL_Running'] == 'Yes' and slave_status['Seconds_Behind_Master'] == 0 and slave_status['Last_Errno'] == 0):
    if system == "Linux":
        p = subprocess.Popen(["/sbin/iptables -F"], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    elif system == "FreeBSD":
        p = subprocess.Popen(["ipfw delete 06666"], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p = subprocess.Popen(["ipfw delete 06667"], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    sys.exit(0)
else:
    if system == "Linux":
        p = subprocess.Popen(["/sbin/iptables -A INPUT -p tcp --dport 80 -j REJECT --reject-with tcp-reset"], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p = subprocess.Popen(["/sbin/iptables -A INPUT -p tcp --dport 8000 -j REJECT --reject-with tcp-reset"], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    elif system == "FreeBSD":
        p = subprocess.Popen(["/sbin/ipfw add 06666 reject tcp from any to me 80"], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p = subprocess.Popen(["/sbin/ipfw add 06667 reject tcp from any to me 8000"], shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    email_body = [
        "From: %s" % email_from,
        "To: %s" % email_to,
        "Subject: %s" % (email_subject %  gethostname()),
        "",
        '\n'.join([ k + ' : ' + str(v) for k,v in slave_status.iteritems()]),
        "\r\n",
        ]

    server = smtplib.SMTP('localhost')
    server.sendmail(email_from, email_to, '\r\n'.join(email_body))
    server.quit()
