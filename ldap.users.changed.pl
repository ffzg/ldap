#!/usr/bin/perl
use warnings;
use strict;
use Data::Dump qw(dump);

my @last;

open(my $fh, '-|', 'git -C out/ log -p --date=iso -n 1 ldap.users');
while(<$fh>) {
	chomp;
	#print "XXX<<<$_\n";
	if ( m/Date:\s+(.+)/ ) {
		print "### $1\n";
	} elsif ( m/^(@@|\Q+++\E|---)/ ) {
		# nop
	} elsif ( s/^([-+])// ) {
		my $op = $1;
		my @v = split(/\s/,$_,2);
		unshift @v, $op;
		#print "XXX v=",dump(@v);
		if ( @last ) {
			#print "XXX last=",dump(@last);
			if ( $last[1] eq $v[1] ) {
				if ( $last[0] eq '-' && $v[0] eq '+' ) {
					print "MODIFY @v\n";
					@last = ();
					@v = ();
				} else {
					die "DIE unhandled combination ",dump( $last[0], $v[0] );
				}
			}
		} elsif ( $op eq '+' ) {
			#print "A @v\n";
		} elsif ( $op eq '-' ) {
			#print "D @v\n";
		} else {
			die @v;
		}
		@last = @v;
	} elsif ( m/^\s/ ) {
		if ( @last ) {
			if ( $last[0] eq '-' ) {
				print "DELETE @last\n";
			} elsif ( $last[0] eq '+' ) {
				print "CREATE @last\n";
			} else {
				die "DIE unhandled last=",dump(@last);
			}
		}
		@last = ();
	} else {
		#print "IGNORE $_\n";
	}
}

 
