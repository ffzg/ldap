#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use MIME::Base64;

my @cols = qw(
uid
hrEduPersonUniqueID
hrEduPersonOIB
mail
hrEduPersonExpireDate
createTimestamp
hrEduPersonAffiliation
displayName
);

my $col2nr;
foreach my $i ( 0 .. $#cols ) {
	$col2nr->{ $cols[$i] } = $i;
}

my $regex = join('|', @cols);

my $user;

open(my $out, '>', 'out/ldap.users');
open(my $ldif, '>', 'out/ldif');

open(my $ldap, '-|', 'sudo -u openldap slapcat');
while(<$ldap>) {
	print $ldif $_;
	chomp;
	if ( m/($regex):(:?)\s(.+)/ ) {
		my ($a,$need_decode,$v) = ( $1,$2, $3 );

		if ( $a eq 'uid' && $user ) {
			my $line = join(" ", map { defined $user->{$_} ? $user->{$_} : '?' } @cols) . "\n";
			print $line;
			print $out $line;
			$user = undef;
		}

		$v = decode_base64($v) if $need_decode;

		if ( $a ne 'displayName' && $v =~ s/\s+/_/g ) {
			# nop
		}

		if ( defined $user->{$a} ) {
			$user->{$a} .= ',' . $v;
		} else {
			$user->{$a} = $v;
		}
	}
}

system 'git -C out diff | grep + >/dev/null && git -C out commit -m $( date +%Y-%m-%d ) -a';
