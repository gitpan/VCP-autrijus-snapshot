#!/usr/local/bin/perl -w

=head1 NAME

t/99cvs_clone_delete_order.t

=head1 DESCRIPTION

Test that VCP::Source::cvs emits clone records in the correct order
when cloning a delete.  This is to address an issue that is reported
by VCP::Dest::cvs of "all revision(s) already integrated" which occurs
because VCP::Source::cvs clones a delete before it clones an edit.

=cut

use File::Basename;
use Test;
use VCP::Dest::perl_data;
use VCP::Filter::changesets;
use VCP::Logger qw( set_quiet_mode );
use VCP::Source::cvs;
use VCP::TestUtils;

use strict;

set_quiet_mode( 1 );

my @vcp = vcp_cmd;

my $progname = basename $0;

my $t = -d 't' ? 't/' : '' ;

my @data;

my @tests = (
sub {
   my $s = VCP::Source::cvs->new( "cvs:t:99cvs_delete_clone_order.c" );
   my $f = VCP::Filter::changesets->new;
   my $d = VCP::Dest::perl_data->new;
   $s->dest( $f );
   $f->dest( $d );

   $s->init;
   $f->init;
   $d->init;

   $d->output( \@data );

   $s->handle_header( {} );
   $s->copy_revs;
   $s->handle_footer( {} );
   ok 0 + @data, 16;
},

sub {
   shift @data; # discard header
   pop @data;   # discard footer
   my %seen;
   my @out_of_order;
   for ( @data ) {
      for my $field qw( previous_id from_id ) {
         push @out_of_order, $_->{$field}
            if $_->{$field} && !$seen{$_->{$field}};
      }
      $seen{$_->{id}}++;
   }
   ok join( ", ", @out_of_order ), "";
},
) ;

plan tests => scalar @tests ;

my $cvs_borken = cvs_borken ;

my $why_skip ;
$why_skip .= cvs_borken;

$why_skip ? skip( $why_skip, '' ) : $_->() for @tests ;
