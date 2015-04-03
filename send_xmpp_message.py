#!/usr/bin/env python
#-*- coding: utf-8 -*-

import xmpp,sys

xmpp_jid = 'me@me.ru'
xmpp_pwd = 'P@ssw0rd'

to = sys.argv[1]
msg = sys.argv[2]

jid = xmpp.protocol.JID(xmpp_jid)
client = xmpp.Client(jid.getDomain(),debug=[])
client.connect()
client.auth(jid.getNode(),str(xmpp_pwd),resource='xmpppy')
client.send(xmpp.protocol.Message(to,msg))
client.disconnect()

#2use ./send_xmpp_message.py me@me.ru "hi"
#apt-get install python-xmpp
#apt-get install python-dnspython
