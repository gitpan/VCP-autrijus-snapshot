#!/usr/local/bin/perl -w

=head1 NAME

03dest_perl_data.t - testing of VCP::Dest::perl_data services

=cut

use strict;

use File::Basename;
use Test;
use VCP::Dest::perl_data;
use VCP::Source::null;

my $t = -d 't' ? 't/' : '' ;

my $progname = basename $0;

my $ofn = $t . $progname . ".log";

my $source = VCP::Source::null->new( "null:" );

my $p;
my $o;

sub r {
   my ( $action, $name, $rev_id, $previous_id ) = @_;
   my $r = VCP::Rev->new(
      action               => $action,
      name                 => $name,
      id                   => "$name#$rev_id",
      source_name          => $name,
      rev_id               => $rev_id,
      source_rev_id        => $rev_id,
      type                 => "text",
      time                 => 0+time,
      source_repo_id       => $progname,
      source               => $source,
      source_filebranch_id => "/depot/$name",
      branch_id            => "/depot",
      previous_id          => $previous_id,
   );

   $r->set_source( $source );
   return $r;
}


my @options = (
   "--repo-id=repo-idfoo",
   "--db-dir=db-dirfoo",
);

my @tests = (
sub {
   $p = VCP::Dest::perl_data->new( "perl_data" ) ;
   ok ref $p, 'VCP::Dest::perl_data';
},

sub {
   $o = join( " ", map "'$_'", $p->options_as_strings );
   ok length $o;
},

(
   map {
      my $option = $_;
      $option =~ s/=.*//;
      sub {
         ok 0 <= index( $o, "'#$option" ), 1, $option;
      };
   } @options
),

sub {
   $p->parse_options( [ @options ] );
   $o = join( " ", map "'$_'", $p->options_as_strings );
   ok length $o;
},

(
   map {
      my $option = $_;
      sub {
         ok 0 <= index( $o, "'$option'" ), 1, $option;
      };
   } @options
),

sub {
   $o = $p->config_file_section_as_string;
   ok $o;
},

(
   map {
      my $option = $_;
      $option =~ s/^--?//;
      $option =~ s/=.*//;
      sub {
         ok 0 <= index( $o, $option ), 1, "$option documented";
      };
   } @options
),

sub {
   my $dest = VCP::Dest::perl_data->new( "perl_data:" );
   $dest->init();
   ## to vcp.log
   $dest->handle_header( {} );
   $dest->handle_rev( r "add", "a", "1", undef );
   $dest->handle_rev( r "edit", "a", "2", undef );
   $dest->handle_footer( {} );
   ## TODO: see if this ended up in the log file
   ok 1;
},

sub {
   my $dest = VCP::Dest::perl_data->new( "perl_data:" );
   $dest->init();
   $dest->output( \my $scalar );
   $dest->handle_header( {} );
   $dest->handle_rev( r "add", "a", "1", undef );
   $dest->handle_rev( r "edit", "a", "2", undef );
   $dest->handle_footer( {} );
   ok $scalar, qr/header.*\ba\b.*\ba\b.*footer/s;
},

sub {
   my $dest = VCP::Dest::perl_data->new( "perl_data:" );
   $dest->init();
   $dest->output( \my @a );
   $dest->handle_header( {} );
   $dest->handle_rev( r "add", "a", "1", undef );
   $dest->handle_rev( r "edit", "a", "2", undef );
   $dest->handle_footer( {} );
   ok 0+@a, 4;
},

sub {
   my $dest = VCP::Dest::perl_data->new( "perl_data:" );
   $dest->init();
   $dest->output( \my %h );
   $dest->handle_header( {} );
   $dest->handle_rev( r "add", "a", "1", undef );
   $dest->handle_rev( r "edit", "a", "2", undef );
   $dest->handle_footer( {} );
   ok join( ",", sort keys %h ), "a#1,a#2,footer,header";
},

) ;

plan tests => scalar( @tests ) ;

$_->() for @tests ;
