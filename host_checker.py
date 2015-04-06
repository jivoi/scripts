#!/usr/bin/env python
# -*- coding: utf-8 -*-

alphabet = (u"alpha", u"beta", u"gamma", u"delta", u"epsilon", u"zeta", u"eta", u"theta", u"iota", u"kappa", u"mu", u"nu", u"xi", u"omicron", u"pi", u"rho", u"sigma", u"tau", u"upsilon", u"phi", u"chi", u"psi", u"omega" )


import stat, sys, os, string, commands, re
print u"Free hostnames :"
try:
	for L in alphabet :	
		commandString = "host " + L
		commandOutput = commands.getoutput(commandString)
		pattern = '192.168.56.1'
		found = re.findall( pattern, commandOutput )		
		if len(found) != 0 :
			print L	

except:
	print u"ERROR"
