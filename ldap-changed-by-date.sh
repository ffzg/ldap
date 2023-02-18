#!/bin/sh

if [ ! -e /tmp/ldap.changed ] ; then
	echo "Create LDAP changes with: ./ldif.changed.pl -n 3 | tee /tmp/ldap.changed"
	exit 1
fi

cat /tmp/ldap.changed | awk '{ print $1" "$2 }' | sort | uniq -c | sort -k 2 -r | less
