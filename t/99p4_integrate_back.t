#!/usr/local/bin/perl -w

=head1 NAME

t/99p4_integrate_back.t

Test that VCP can copy past an integration from the child back to the
parent

=head2 Original Description

Perforce job014469, reported by gerry:

   VCP crashes in p4 to p4 conversions if files have been
   integrated back to parent.
   Reproduction steps:
   p4 add a
   p4 integ a b
   p4 submit
   p4 edit b
   p4 submit
   p4 integ b a
   p4 resolve -am
   p4 submit
   When vcp attempts to copy the above depot it will
   generate a fatal error: "cannot open a#2"

=head2 As reproduced:

In order to reproduce this, we had to add a "p4 submit a" after the "p4
add a".

The fatal error we got was:

   ***BUG REPORT***
   can't check out a#2 @4 <//depot/> (text) integrate 2004-09-09 04:00:00Z testuser "test\n"

=cut

use strict ;

use Test ;
use Cwd;
use File::Basename;
use VCP::Dest::p4;
use VCP::Source::p4;
use VCP::Logger qw( set_quiet_mode );
use VCP::TestUtils;

set_quiet_mode( 1 );

my @vcp = vcp_cmd;

my $progname = basename $0;

my $t = -d 't' ? 't/' : '' ;

my $p4root = tmpdir "p4root";

my $p4spec = "p4:testuser\@$p4root://depot/...";

my $change_spec;

sub submit {
   my $dest = shift;
   $dest->p4( [ "change", "-o" ], undef, \my $change_spec ) ;
   $change_spec =~ s/^(Description|Files):.*\r?\n\r?.*//ms
      or die "couldn't remove change file list and description\n$change_spec" ;

   $change_spec = join "",
       $change_spec,
       <<CHANGE_SPEC_END,
Description: test

Files:
CHANGE_SPEC_END
       map " //depot/$_\n", @_;

   VCP::Logger::lg $change_spec;
   $dest->p4( [ "submit", "-i" ], \$change_spec );
}


my @tests = (
sub {
   ## Build the test repository

   my $start_dir = cwd;
      ## the dest chdir()s around when we create the test repository, we
      ## need this to get back to where we belong.

   my $dest = VCP::Dest::p4->new(
       $p4spec,
       [ qw( --init-p4d --delete-p4d-dir ) ]
   );
   $dest->init;

   ## the test file
   my $a_fn = $dest->work_path( "co", "a" );
   $dest->mkpdir( $a_fn );
   open  A, "> $a_fn" or die "$!: $a_fn\n";
   print A "test\n"   or die "$!: $a_fn\n";
   close A            or die "$!: $a_fn\n";

   ## the recipe from the bug report
   $dest->p4( [qw( add a )] );
   submit( $dest, "a" );  ## Not in recipe, had to add to make it work
   $dest->p4( [qw( integ a b )] );
   submit( $dest, "b" );
   $dest->p4( [qw( edit b )] );
   submit( $dest, "b" );
   $dest->p4( [qw( integ b a )] );
   $dest->p4( [qw( resolve -am )] );
   submit( $dest, "a" );

   ## cleanup
   $dest = undef;
   chdir $start_dir or die "$!: $start_dir";
   ok 1;
},

sub {
   my $ok = eval {
      run [ @vcp, $p4spec, "--run-p4d", "null:" ], \undef;
      1;
   };
   ok $ok ? '' : $@, '';
},


) ;

plan tests => scalar @tests ;

my $p4d_borken = p4d_borken ;

my $why_skip ;
$why_skip .= "p4 command not found\n"  unless ( `p4 -V`  || 0 ) =~ /^Perforce/ ;
$why_skip .= "$p4d_borken\n"           if $p4d_borken ;

$why_skip ? skip( $why_skip, '' ) : $_->() for @tests ;

VCP::Utils::p4->_cleanup_p4;
