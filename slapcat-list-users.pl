#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use MIME::Base64;

my @cols = qw(
uid
hrEduPersonUniqueID
hrEduPersonExpireDate
createTimestamp
modifyTimestamp
hrEduPersonAffiliation
displayName
);

my $col2nr;
foreach my $i ( 0 .. $#cols ) {
	$col2nr->{ $cols[$i] } = $i;
}

my $regex = join('|', @cols);

my $user;

open(my $ldap, '-|', 'sudo -u openldap slapcat');
while(<$ldap>) {
	chomp;
	if ( m/($regex):(:?)\s(.+)/ ) {
		my ($a,$need_decode,$v) = ( $1,$2, $3 );

		if ( $a eq 'uid' && $user ) {
			print join(" ", map { $user->{$_} } @cols), "\n";
			$user = undef;
		}

		$v = decode_base64($v) if $need_decode;

		if ( $a ne 'displayName' && $v =~ s/\s+/_/g ) {
			# nop
		}

		$user->{$a} = $v;
	}
}
