package VCP::Dest::perl_data ;

=head1 NAME

VCP::Dest::perl_data - emit metadata to a log file

=head1 SYNOPSIS

    vcp ... perl_data:         # to vcp.log
    vcp ... perl_data:-:       # to STDOUT
    vcp ... perl_data:foo.log: # to foo.log

=head1 DESCRIPTION

Dump all data structures to a log file or STDOUT.

This is intended to be used when reproducing bugs to capture a metadata
stream that can be copy-pasted-tweaked in to a t/99*.t test program.

Not a supported module, API and behavior may change without warning.

See source code and test suites for how to capture data structures
in scalars, arrays and hashes.

=cut

$VERSION = 0.1 ;

@ISA = qw( VCP::Dest );

use strict ;

use VCP::Dest;
use VCP::Logger qw( lg_fh );
use VCP::Utils qw( empty );

sub new {
   my $self = shift->SUPER::new;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_repo_spec( $spec )
      unless empty $spec;

   $self->parse_options( $options );

   return $self;
}


sub init {
   my $self = shift;
   
   my $out_fn = $self->repo_server;

   if ( empty $out_fn ) {
      $self->{OUTPUT} = lg_fh;
   }
   elsif ( $out_fn eq "-" ) {
      $self->{OUTPUT} = \*STDOUT;
   }
   else {
      open $self->{OUTPUT}, "> $out_fn"
          or die "$!: $out_fn\n";
   }

   require Data::Dumper;
}


sub output {
   my $self = shift;
   $self->{OUTPUT} = shift if @_;
   return $self->{OUTPUT};
}


sub emit {
   my $self = shift;
   my ( $name, $structure ) = @_;
   my $output = $self->{OUTPUT};
   my $type = ref $output;

   if ( $type eq "ARRAY" ) {
      push @$output, $structure;
      return;
   }
   if ( $type eq "HASH" ) {
      $output->{ $name eq "rev" ? $structure->{id} : $name } = $structure;
      return;
   }

   local $Data::Dumper::Indent    = 1;
   local $Data::Dumper::Quotekeys = 0;
   local $Data::Dumper::Terse     = 1;
   local $Data::Dumper::Sortkeys  = 1;
   local $Data::Dumper::Purity    = 1;

   local $Data::Dumper::Bless = $name;

   my $dump = Data::Dumper::Dumper( { %{$structure} } );
       ## debless with {%{}}

   $dump =~ s/.*?{(.*)}.*/$name($1);\n/s;
       ## Make it look like a function call

   if ( $type eq "SCALAR" ) {
      $$output .= $dump;
   }
   else {
      print $output $dump;
   }
}


sub handle_header {
   my $self = shift;
   $self->emit( "header", shift );
}

sub handle_rev {
   my $self = shift;
   $self->emit( "rev", shift );
}


sub handle_footer {
   my $self = shift;
   $self->emit( "footer", shift );
}


=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
