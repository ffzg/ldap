#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use MIME::Base64;
use POSIX qw(strftime);
use Data::Dump qw(dump);

my @cols = qw(
uid
hrEduPersonUniqueID
hrEduPersonExpireDate
modifyTimestamp
pwdChangedTime
createTimestamp
hrEduPersonAffiliation
displayName
);

my $regex = join('|', @cols);

my $user;

my $today = $ENV{TODAY} || strftime("%Y%m%d", localtime);
warn "# today $today";

sub check_user {
	if (
		! defined($user->{uid}) ||
		$user->{hrEduPersonExpireDate} eq 'NONE' ||
		$user->{hrEduPersonExpireDate} gt $today
	) {
		return 0;
	}

	my $line = join(" ", map { defined $user->{$_} ? $user->{$_} : '?' } @cols) . "\n";
	print $line;
	#print "# user = ",dump($user), $/;
	$user = undef;
	return 1;
}

my $count;

my $ldif = $ENV{LDIF} || "out/ldif";
# git clone -b before-delete out out.before-delete
#my $ldif = "out.before-delete/ldif";
warn "# ldif $ldif";

open(my $ldap, '<', $ldif);
while(<$ldap>) {
	chomp;

	if ( $_ eq '' && $user ) {
		if ( check_user ) {
			$count++;
			#exit 0 if $count == 10;
		}
	}

	if ( m/($regex):(:?)\s(.+)/ ) {
		my ($a,$need_decode,$v) = ( $1,$2, $3 );

		$v = decode_base64($v) if $need_decode;

		if ( $a ne 'displayName' && $v =~ s/\s+/_/g ) {
			# nop
		}

		$user->{$a} = $v;
	}
}

check_user;


