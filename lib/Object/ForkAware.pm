use strict;
use warnings;
package Object::ForkAware;
# ABSTRACT: ...

sub new
{
    my ($class, %opts) = @_;

    my $self = {};
    $self->{_create} = $opts{create} || die 'missing required option: create';

    $self = bless($self, $class);

    # TODO: lazy option?
    $self->_create_obj;

    return $self;
}

sub _create_obj
{
    my $self = shift;

    my $obj = $self->{_create}->();
    $self->{_pid} = $$;
    $self->{_tid} = threads->tid if $INC{'threads.pm'};
    $self->{_obj} = $obj;
}

sub _get_obj
{
    my $self = shift;

    if ($$ != $self->{_pid}
        or defined $self->{_tid} and $self->{_tid} != threads->tid)
    {
        $self->_create_obj;
    }

    return $self->{_obj};
}

sub isa
{
    my ($self, $class) = @_;
    $self->SUPER::isa($class) || $self->_get_obj->isa($class);
}

sub can
{
    my ($self, $class) = @_;
    $self->SUPER::can($class) || $self->_get_obj->can($class);
}

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;

    # Remove qualifier from original method name...
    (my $called = $AUTOLOAD) =~ s/.*:://;
    return $self->_get_obj->$called(@_);
}

sub DESTROY {}  # avoid calling AUTOLOAD at destruction time

1;
__END__

=pod

=head1 SYNOPSIS

...

=head1 DESCRIPTION


=head1 FUNCTIONS/METHODS

=over

=item * C<foo>

=back

...

=head1 SUPPORT

Bugs may be submitted through L<https://rt.cpan.org/Public/Dist/Display.html?Name=Object-ForkAware>
or L<bug-Object-ForkAware@rt.cpan.org>.
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

...

=cut
