#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use MIME::Base64;
use Encode;
use POSIX qw(strftime mktime);
use Data::Dump qw(dump);

# check if students have jmbag

my $debug = $ENV{DEBUG} || 0;

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
mail
hrEduPersonUniqueNumber
hrEduPersonExpireDate
createTimestamp
hrEduPersonAffiliation
displayName
ou
);

my $regex = join('|', @cols);

my $user;

my $today = $ENV{TODAY} || strftime("%Y%m%d", localtime);
warn "# today $today";

my $today_t = yyyymmdd_to_t( $today );

my $stat;

sub check_user {
	warn "### user = ",dump($user) if $debug;

	$stat->{ou}->{ $user->{ou} }++;

	if (
		! defined($user->{uid}) ||
		$user->{hrEduPersonExpireDate} eq 'NONE'
	) {
		return 0;
	}

	my $expire_t = yyyymmdd_to_t( $user->{hrEduPersonExpireDate} );

	my $expire_in_days = ( $expire_t - $today_t ) / ( 24 * 60 * 60 );

=for later
	if ( $expire_in_days == 0 ) {
		print "XXX LOCK ",dump( $user );
		lock_uid( $user->{uid} );
	} elsif ( $expire_in_days == 14 ) {	# FIXME 14, 30?
		print "XXX WARN about expire ",dump( $user );
		my $expire_date = $user->{hrEduPersonExpireDate};
		$expire_date =~ s/^(2\d\d\d)(\d\d)(\d\d)/$1-$2-$3/;
		send_email( $user->{hrEduPersonUniqueID}, $user->{mail}, $expire_in_days, $expire_date );
	}

	if ( $expire_in_days > 30 ) {
		return 1;
	}
=cut

	my $line = join(" ", map { defined $user->{$_} ? $user->{$_} : '?' } @cols) . "\n";
	#print $line;
	#printf "%-3d %s", $expire_in_days, $line;
	print $line if ( $user->{hrEduPersonAffiliation} =~ m/student/ && ! exists $user->{JMBAG} );
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
			last if ( $debug && $count == 10 );

		}
		$user = undef;
	}

	if ( m/($regex):(:?)\s(.+)/ ) {
		my ($a,$need_decode,$v) = ( $1,$2, $3 );

		if ( $need_decode ) {
			$v = decode_base64($v);
			Encode::_utf8_on($v);
		}


		if ( $a eq 'hrEduPersonUniqueNumber' ) {
			my ($name,$num) = split(/:\s*/, $v, 2);
			$user->{$name} = $num;
			$v =~ s/\s+//;
		} elsif ( $a ne 'displayName' && $v =~ s/\s+/_/g ) {
			# nop
		}

		if ( defined $user->{$a} ) {
			$user->{$a} .= ',' . $v;
		} else {
			$user->{$a} = $v;
		}
	}
}

check_user;

print "# stat = ",dump($stat),$/;

