use strict;
use warnings FATAL => 'all';
package PidTracker;

our $instance = -1;

sub new
{
    my $class = shift;
    return bless {
        pid => $$,
        instance => ++$instance,
    }, $class;
}

sub pid { shift->{pid} }

sub instance { shift->{instance} }

sub foo { 'a sub that returns foo' }

1;
