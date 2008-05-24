##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals;

use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.084';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Useless interpolation of literal string};
Readonly::Scalar my $EXPL => [51];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'allow',
            description        =>
                'Kinds of delimiters to permit, e.g. "qq{", "qq(", "qq[", "qq/".',
            default_string     => $EMPTY,
            parser             => \&_parse_allow,
        },
    );
}

sub default_severity { return $SEVERITY_LOWEST        }
sub default_themes   { return qw( core pbp cosmetic ) }
sub applies_to       { return qw(PPI::Token::Quote::Double
                                 PPI::Token::Quote::Interpolate) }

#-----------------------------------------------------------------------------

Readonly::Scalar my $MAX_SPECIFICATION_LENGTH => 3;

sub _parse_allow {
    my ($self, $parameter, $config_string) = @_;

    my @allow;

    if (defined $config_string) {
        @allow = words_from_string( $config_string );
        #Try to be forgiving with the configuration...
        for (@allow) {
            m{ \A qq }mx || ($_ = 'qq' . $_)
        }  #Add 'qq'
        for (@allow) {
            (length $_ <= $MAX_SPECIFICATION_LENGTH) || chop
        }    #Chop closing char
    }

    $self->{_allow} = \@allow;

    return;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Skip if this string needs interpolation
    return if _has_interpolation($elem);

    # Overlook allowed quote styles
    return if any { $elem =~ m{ \A \Q$_\E }mx } @{ $self->{_allow} };

    # Must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _has_interpolation {
    my $elem = shift;
    return $elem =~ m{ (?<!\\) [\$\@] \S+ }mx      #Contains unescaped $. or @.
        || $elem =~ m{ \\[tnrfbae0xcNLuLUEQ] }mx;   #Containts escaped metachars
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals - Always use single quotes for literal strings.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

Don't use double-quotes or C<qq//> if your string doesn't require
interpolation.  This saves the interpreter a bit of work and it lets
the reader know that you really did intend the string to be literal.

  print "foobar";     #not ok
  print 'foobar';     #ok
  print qq/foobar/;   #not ok
  print q/foobar/;    #ok

  print "$foobar";    #ok
  print "foobar\n";   #ok
  print qq/$foobar/;  #ok
  print qq/foobar\n/; #ok

  print qq{$foobar};  #preferred
  print qq{foobar\n}; #preferred

=head1 CONFIGURATION

The types of quoting styles to exempt from this policy can be
configured via the C<allow> option.  This must be a
whitespace-delimited combination of some or all of the following
styles: C<qq{}>, C<qq()>, C<qq[]>, and C<qq//>.

This is useful because some folks have configured their editor to
apply special syntax highlighting within certain styles of quotes.
For example, you can tweak C<vim> to use SQL highlighting for
everything that appears within C<qq{}> or C<qq[]> quotes.  But if
those strings are literal, Perl::Critic will complain.  To prevent
this, put the following in your F<.perlcriticrc> file:

  [ValuesAndExpressions::ProhibitInterpolationOfLiterals]
  allow = qq{} qq[]

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
