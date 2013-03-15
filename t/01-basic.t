use strict;
use warnings FATAL => 'all';

use Test::More tests => 17;
use Test::Warnings;

use Object::ForkAware;

use lib 't/lib';
use PidTracker;

my $Test = Test::Builder->new;

{
    # the failure case...

    my $obj = PidTracker->new;
    is($obj->pid, $$, 'object was created in the current process');
    is($obj->instance, 0, 'this is instance #0');

    looks_like_a_pidtracker($obj);

    my $parent_pid = $$;
    my $child_pid = fork;

    if (not defined $child_pid)
    {
        die 'cannot fork: ', $!;
    }
    elsif ($child_pid == 0)
    {
        # child

        isnt($obj->pid, $$, 'object no longer has the right pid');
        is($obj->instance, 0, 'object is still instance #0');
        exit;
    }

    # make sure we do not continue until after the child process exits
    waitpid($child_pid, 0);
    $Test->current_test($Test->current_test + 3);
}

$PidTracker::instance = -1;
{
    # now wrap in a ForkAware object and watch the magic!

    my $obj = Object::ForkAware->new(create => sub { PidTracker->new });

    is($PidTracker::instance, 0, 'an object has been instantiated already');

    looks_like_a_pidtracker($obj);

    is($obj->pid, $$, 'object was created in the current process');
    is($obj->instance, 0, 'this is instance #0');

    # now fork and see what happens

    my $parent_pid = $$;
    my $child_pid = fork;

    if (not defined $child_pid)
    {
        die 'cannot fork: ', $!;
    }
    elsif ($child_pid == 0)
    {
        # child

        isnt($$, $parent_pid, 'we are no longer the same process');

        ok($obj->isa('Object::ForkAware'), 'object is ForkAware');

        looks_like_a_pidtracker($obj);
        is($obj->pid, $$, 'object was created in the current process');
        is($obj->instance, 1, 'this is now instance #1');
        exit;
    }

    # make sure we do not continue until after the child process exits
    waitpid($child_pid, 0);
    $Test->current_test($Test->current_test + 6);
}

sub looks_like_a_pidtracker
{
    my $obj = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    subtest 'object quacks like a PidTracker' => sub {
        ok($obj->isa('PidTracker'), '->isa works as if we called it on the target object');
        ok($obj->can('foo'), '->can works as if we called it on the target object');
        is($obj->can('foo'), \&PidTracker::foo, '...and returns the correct reference');
        is($obj->foo, 'a sub that returns foo', 'method responds properly');
    };
}

