#!/bin/sh -xe

ldappasswd -Q -H ldapi:/// -Y EXTERNAL -s $( pwgen 12 1 ) uid=$1,dc=ffzg,dc=hr

