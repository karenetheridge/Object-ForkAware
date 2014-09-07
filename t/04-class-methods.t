use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Object::ForkAware;

is(
    exception {
        ok(Object::ForkAware->isa('Object::ForkAware'),
            'isa as a class method checks isa of class');
        Object::ForkAware->isa('Warble');
    },
    undef,
    "isa as a class method doesn't crash",
);

is(
    exception {
        is(Object::ForkAware->can('can'), \&Object::ForkAware::can,
            'can as a class method returns correct sub');
        Object::ForkAware->can('nomethod');
    },
    undef,
    "can as a class method doesn't crash",
);

done_testing;
