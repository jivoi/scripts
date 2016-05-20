#!/usr/bin/python

# top5log 25 < apache.log
# where the argument 25 represents how many days ago the day of interest is (the default is 1, i.e., yesterday), and apache.log is the name of the log file, which the script reads via stdin. The output looks like this:

# Jul 03, 2013 pages
#     907  /all-this/2013/06/feedle-dee-dee/
#     813  /all-this/
#     749  /all-this/2013/07/last-i-hope-thoughts-on-rss/
#      74  /all-this/2007/03/improved-currency-conversion-card/
#      74  /all-this/2009/08/camry-smart-key-battery-replacement/
#    7134  total


import re
import sys
from datetime import datetime, date, timedelta
from collections import Counter

# Define the day of interest in the Apache common log format.
try:
  daysAgo = int(sys.argv[1])
except:
  daysAgo = 1
theDay = date.today() - timedelta(daysAgo)
apacheDay = theDay.strftime('[%d/%b/%Y:')

# Regex for the Apache common log format.
parts = [
    r'(?P<host>\S+)',                   # host %h
    r'\S+',                             # indent %l (unused)
    r'(?P<user>\S+)',                   # user %u
    r'\[(?P<time>.+)\]',                # time %t
    r'"(?P<request>.*)"',               # request "%r"
    r'(?P<status>[0-9]+)',              # status %>s
    r'(?P<size>\S+)',                   # size %b (careful, can be '-')
    r'"(?P<referrer>.*)"',              # referrer "%{Referer}i"
    r'"(?P<agent>.*)"',                 # user agent "%{User-agent}i"
]
pattern = re.compile(r'\s+'.join(parts)+r'\s*\Z')

# Regex for a feed request.
feed = re.compile(r'/all-this/(\d\d\d\d/\d\d/[^/]+/)?feed/(atom/)?')

# Change Apache log items into Python types.
def pythonized(d):
  # Clean up the request.
  d["request"] = d["request"].split()[1]

  # Some dashes become None.
  for k in ("user", "referrer", "agent"):
    if d[k] == "-":
      d[k] = None

  # The size dash becomes 0.
  if d["size"] == "-":
    d["size"] = 0
  else:
    d["size"] = int(d["size"])

  # Convert the timestamp into a datetime object. Accept the server's time zone.
  time, zone = d["time"].split()
  d["time"] = datetime.strptime(time, "%d/%b/%Y:%H:%M:%S")

  return d

# Is this hit a page?
def ispage(hit):
  # Failures and redirects.
  hit["status"] = int(hit["status"])
  if hit["status"] < 200 or hit["status"] >= 300:
    return False

  # Feed requests.
  if feed.search(hit["request"]):
    return False

  # Requests that aren't GET.
  if hit["request"][0:3] != "GET":
    return False

  # Images, sounds, etc.
  if hit["request"].split()[1][-1] != '/':
    return False

  # Must be a page.
  return True

# Regexes for internal and Google search referrers.
internal = re.compile(r'https?://(www\.)?leancrew\.com.*')
google = re.compile(r'https?://(www\.)?google\..*')

# Is the referrer interesting? Internal and Google referrers are not.
def goodref(hit):
  if hit['referrer']:
    return not (google.search(hit['referrer']) or
                internal.search(hit['referrer']))
  else:
    return False

# Initialize.
pages = []

# Parse all the lines associated with the day of interest.
for line in sys.stdin:
  if apacheDay in line:
    m = pattern.match(line)
    hit = m.groupdict()
    if ispage(hit):
      pages.append(pythonized(hit))
    else:
      continue

# Show the top five pages and the total.
print '%s pages' % theDay.strftime("%b %d, %Y")
pageViews = Counter(x['request'] for x in pages)
top5 = pageViews.most_common(5)
for p in top5:
  print "  %5d  %s" % p[::-1]
print "  %5d  total" % len(pages)

# Show the top five referrers.
print '''
%s referrers''' % theDay.strftime("%b %d, %Y")
referrers = Counter(x['referrer'] for x in pages if goodref(x) )
top5 = referrers.most_common(5)
for r in top5:
  print "  %5d  %s" % r[::-1]
