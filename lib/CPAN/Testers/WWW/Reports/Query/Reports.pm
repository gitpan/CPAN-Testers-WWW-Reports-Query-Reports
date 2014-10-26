package CPAN::Testers::WWW::Reports::Query::Reports;

use strict;
use warnings;

our $VERSION = '0.02';
 
#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Reports::Query::Reports - Retrieve CPAN Testers metadata direct from the CPAN Testers website.

=head1 DESCRIPTION
 
This module queries the CPAN Testers website and retrieves a data set. For a
date request, the data set returned relates to the ids that can be retrieved
for that date. A range request will return the records for the requested IDs.
 
=head1 SYNOPSIS

    # establish the object
    my $query = CPAN::Testers::WWW::Reports::Query::Reports->new;

    # get list of ids for a particular date
    my $result = $query->date(
        '2012-02-08' # must be YYYY-MM-DD format
    );

    # $query is a hash ref
    print "From: $result->{from}, To: $result->{to}, Range: $result->{range}\n"; 

    # $result->{list} is an array of the actual ids posted for the given date.
    # note that this list may not include all ids within $result->{range}.
    print "List: " . join(', ',@{$result->{list}}) . "\n";


    # get metabase for a range of ids
    my $result = $query->range(
        '20080300-20120330'

        # '20120330'  # just get <id>
        # '20120330-' # from <id> until the latest [see caveat]
        # '-20120330' # previous <n> reports up to <id> [see caveat]
        # '-'         # the latest <n> reports [see caveat]
    );

    # $result is a hash ref, with the reports ids as the top level keys
    my @ids = sort keys %$result;
    my $id  = $ids[0];
    print "id = $id, dist = '$result->{$id}{dist}', version = '$result->{$id}{version}'\n";


    # get the raw data for all results, or a specific version if supplied
    my $data = $query->raw;


=head2 Caveat

When using the range parameter, note that at most 2500 records will be 
returned. This is to avoid accidental request for all the records! 

This value may change in the future.

=cut
 
#----------------------------------------------------------------------------
# Library Modules

use WWW::Mechanize;
use JSON::XS;

#----------------------------------------------------------------------------
# Variables

my $URL = 'http://www.cpantesters.org/cgi-bin/reports-metadata.cgi';
#$URL = 'http://reports/cgi-bin/reports-metadata.cgi';    # local test version

my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Linux Mozilla' );

# -------------------------------------
# Program

sub new {
    my($class, %hash) = @_;
    my $self = {};
    bless $self, $class;

    return $self;
}

sub raw {
    my $self    = shift;
    return $self->{content};
}
  
sub date {
    my $self    = shift;
    my $date    = shift || return;

    return unless($date =~ /^\d{4}\-\d{2}\-\d{2}$/);
    
    return unless($self->_request( "date=$date" ));

    return $self->_parse();
}

sub range {
    my $self    = shift;
    my $range   = shift || return;

    return unless($range =~ /^(\d+)?\-(\d+)?$/ || $range =~ /^(\d+)$/);

    return unless($self->_request( "range=$range" ));

    return $self->_parse();
}

sub _request {
    my $self    = shift;
    my $param   = shift || return;

    my $url = join( '?', $URL, $param );
    #print "URL: $url\n";
	eval { $mech->get( $url ); };
    if($@ || !$mech->success()) {
        die $@;
        return;
    }

    $self->{content} = $mech->content;
}

sub _parse {
    my $self    = shift;

    return decode_json($self->{content});
}

q("With thanks to the 2012 QA Hackathon");

__END__

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::WWW::Testers. Requires a hash of parameters, with
'config' being the only mandatory key. Note that 'config' can be anything that
L<Config::IniFiles> accepts for the I<-file> option.

=back

=head2 Search Methods

=over 4

=item * date

For the given date, returns a hash describing the IDs accessible for that date.

=item * range

For the given range, returns the metadata records stored for those IDs.

=back

=head2 Data Methods

=over 4

=item * raw

Returns the raw content returned from the server.

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN::Testers::WWW::Reports::Query::Reports

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Reports>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

Initially released during the 2012 QA Hackathon in Paris.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2012 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
