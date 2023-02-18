#!/usr/bin/perl
use warnings;
use strict;
use Data::Dump qw(dump);

my $date;
my $uid;

sub dump_uid {
	foreach my $login ( keys %$uid ) {
		print "$date $uid->{$login} $login\n";
	}
}

open(my $fh, '-|', "git -C out/ log -p --date=iso @ARGV ldif");
while(<$fh>) {
	chomp;
	#print "XXX<<<$_\n";
	if ( m/^Date:\s+(\S+)/ ) {
		dump_uid; $uid = undef;
		#print "### $1\n";
		$date = $1;
	} elsif ( s/^([-+])uid: (.*)// ) {
		my ( $op, $login ) = ($1,$2);
		if ( exists $uid->{$login} ) {
			if ( $op eq '+' && $uid->{$login} eq '-' ) {
				delete $uid->{$login};
			} elsif ( $op eq '-' && $uid->{$login} eq '+' ) {
				delete $uid->{$login};
			} else {
				die "$login $op $uid->{$login}";
			}
		} else {
			$uid->{$login} = $op;
		}
	} else {
		#print "IGNORE $_\n";
	}
}

dump_uid;
