#!/usr/bin/env python3
# coding: utf8

"""
A simple wrapper for the `mailx` command.
Purpose
-------
Send an email notification to yourself from a Python script.
"""

import os

DEBUG = True
# DEBUG = False


class NoSubjectError(Exception):
    pass


class NoRecipientError(Exception):
    pass


def send_email(to='', subject='', body=''):
    if not subject:
        raise NoSubjectError
    if not to:
        raise NoRecipientError
    #
    if not body:
        cmd = """mailx -s "{s}" < /dev/null "{to}" 2>/dev/null""".format(
            s=subject, to=to
        )
    else:
        cmd = """echo "{b}" | mailx -s "{s}" "{to}" 2>/dev/null""".format(
            b=body, s=subject, to=to
        )
    if DEBUG:
        print("#", cmd)
    #
    os.system(cmd)


def main():
    send_email(to="to@email.com",
               subject="subject")
    #
    send_email(to="to@email.com",
               subject="subject",
               body='this is the body of the email')

#############################################################################

if __name__ == "__main__":
    main()