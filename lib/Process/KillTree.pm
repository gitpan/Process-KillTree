package Process::KillTree;

use 5.010;
use strict;
use warnings;

use Exporter::Lite;
our @EXPORT_OK = qw(kill_tree);

our $VERSION = '0.03'; # VERSION

our %SPEC;

$SPEC{kill_tree} = {
    summary => 'Kill process and all its descendants '.
        '(children, grandchildren, ...)',
    description => <<'_',

To find out about child processes, Sys::Statistics::Linux::Processes is used on
Linux. Croaks on other operating systems.

Returns the killed PIDs.

_
    args => {
        pid => ['int' => {
            summary => 'Process ID to kill',
            description => 'Either pid or pids must be specified',
        }],
        pids => ['array' => {
            of => 'int*',
            summary => 'Process IDs to kill',
            description => 'Either pid or pids must be specified',
        }],
        signal => ['str' => {
            summary => 'Signal to use, either numeric (e.g. 1), '.
                'or string (e.g. KILL)',
            default => 'TERM',
        }],
        action => ['code' => {
            summary => 'If specified, will call action instead of killing '.
                'the processes',
            description => <<'_',

Code will be supplied $pids, an arrayref containing all the PIDs to kill.

_
        }],
    },
    result_naked => 1,
    features => {
        dry_run => 1,
    },
};
sub kill_tree {
    my %args = @_;
    my @pids0;
    push @pids0, $args{pid} if $args{pid};
    push @pids0, @{$args{pids}} if $args{pids};
    @pids0 or die "Please specify at least 1 PID";
    my $signal = $args{signal} // "TERM";

    my %parents; # key = pid, val = ppid
    my %pgrps; # key = pid, val = pgrp
    if ($^O =~ /linux/i) {
        eval { require Sys::Statistics::Linux::Processes };
        die "Can't load Sys::Statistics::Linux::Processes, ".
            "please install it first" if $@;
        my $lxs = Sys::Statistics::Linux::Processes->new;
        $lxs->init;
        my $psinfo = $lxs->get;
        for my $pid (keys %$psinfo) {
            $parents{$pid} = $psinfo->{$pid}{ppid};
            $pgrps{$pid} = $psinfo->{$pid}{pgrp};
        }
    } else {
        die "Unknown OS ($^O), can't get process table for this OS";
    }

    my @pids;
    if ($args{_pgrp}) {
        my @pgrps = map { $pgrps{$_} } @pids0;
        for my $pid (keys %pgrps) {
            push @pids, $pid if $pgrps{$pid} ~~ @pgrps;
        }
    } else {
        my %pids;
        my $_push;
        $_push = sub {
            for my $a (@_) {
                next if $pids{$a};
                push @pids, $a;
                $pids{$a} = 1;
                for my $c (keys %parents) {
                    next if $pids{$c};
                    $_push->($c) if $parents{$c} && $parents{$c} == $a;
                }
            }
        };
        $_push->(@pids0);
        @pids = reverse @pids; # kill child first, then parent
    }

    unless ($args{-dry_run}) {
        if ($args{action}) {
            $args{action}->(\@pids);
        } else {
            kill $signal, @pids;
        }
    }

    return \@pids;
}

1;
# ABSTRACT: Kill process and all its descendants (children, grandchildren, ...)


=pod

=head1 NAME

Process::KillTree - Kill process and all its descendants (children, grandchildren, ...)

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Process::KillTree qw(kill_tree);

 my $pid = ...;
 kill_tree pid => $pid, signal => 'KILL';

=head1 DESCRIPTION

This module provides kill_tree().

=head1 SEE ALSO

L<Process::KillGroup>

=head1 FUNCTIONS


=head2 kill_tree(%args) -> [status, msg, result, meta]

Kill process and all its descendants (children, grandchildren, ...).

To find out about child processes, Sys::Statistics::Linux::Processes is used on
Linux. Croaks on other operating systems.

Returns the killed PIDs.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<code>

If specified, will call action instead of killing the processes.

Code will be supplied $pids, an arrayref containing all the PIDs to kill.

=item * B<pid> => I<int>

Process ID to kill.

Either pid or pids must be specified

=item * B<pids> => I<array>

Process IDs to kill.

Either pid or pids must be specified

=item * B<signal> => I<str> (default: "TERM")

Signal to use, either numeric (e.g. 1), or string (e.g. KILL).

=back

Return value:

Returns an enveloped result (an array). First element (status) is an integer containing HTTP status code (200 means OK, 4xx caller error, 5xx function error). Second element (msg) is a string containing error message, or 'OK' if status is 200. Third element (result) is optional, the actual result. Fourth element (meta) is called result metadata and is optional, a hash that contains extra information.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

