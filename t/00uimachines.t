#!/usr/local/bin/perl -w

=head1 NAME

00uimachines.t - testing of VCP::UIMachines

=cut

use strict ;

use Carp ;
use Test ;
use VCP::UIMachines;

## TODO: actually run the machine; perhaps make this or a part of
## this be generated by stml.

my @tests = (
sub { ok 1 },
) ;

plan tests => scalar( @tests ) ;

$_->() for @tests ;
