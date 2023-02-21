#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use MIME::Base64;
use POSIX qw(strftime mktime);
use Data::Dump qw(dump);

sub yyyymmdd_to_t {
	my $yyyymmdd = shift;
	return mktime( 0,0,0,
		substr($yyyymmdd,6,2),
		substr($yyyymmdd,4,2),
		substr($yyyymmdd,0,4) - 1900,
	);
}

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

my $today_t = yyyymmdd_to_t( $today );

sub check_user {
	if (
		! defined($user->{uid}) ||
		$user->{hrEduPersonExpireDate} eq 'NONE'
	) {
		return 0;
	}

	my $expire_t = yyyymmdd_to_t( $user->{hrEduPersonExpireDate} );

	my $expire_in_days = ( $expire_t - $today_t ) / ( 24 * 60 * 60 );

	if ( $expire_in_days == 0 ) {
		print "XXX LOCK ",dump( $user );
	} elsif ( $expire_in_days == 14 ) {
		print "XXX WARN about expire ",dump( $user );
	}

	if ( $expire_in_days > 30 ) {
		return 1;
	}

	my $line = join(" ", map { defined $user->{$_} ? $user->{$_} : '?' } @cols) . "\n";
	#print $line;
	printf "%-3d %s", $expire_in_days, $line;
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


