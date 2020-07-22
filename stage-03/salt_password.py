#!/usr/bin/python3

import sys, crypt

if len(sys.argv) == 1:
    sys.exit("You must supply a password")
print (crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))
