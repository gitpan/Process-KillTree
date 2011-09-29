package Process::KillGroup;

use 5.010;
use strict;
use warnings;

use Data::Clone;
use Exporter::Lite;
use Process::KillTree;

our @EXPORT_OK = qw(kill_group);

our $VERSION = '0.02'; # VERSION

our %SPEC;

$SPEC{kill_group} = clone($Process::KillTree::SPEC{kill_tree});
$SPEC{kill_group}{summary} = "Kill process and all other belonging to ".
    "the same process group";
sub kill_group {
    Process::KillTree::kill_tree(@_, _pgrp=>1);
}

1;
# ABSTRACT: Kill process and all other belonging to the same process group


=pod

=head1 NAME

Process::KillGroup - Kill process and all other belonging to the same process group

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Process::KillGroup qw(kill_group);

 my $pid = ...;
 kill_group pid => $pid, signal => 'KILL';

=head1 DESCRIPTION

This module provides kill_group().

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 kill_group(%args) -> RESULT


Kill process and all other belonging to the same process group.

To find out about child processes, Sys::Statistics::Linux::Processes is used on
Linux. Croaks on other operating systems.

Returns the killed PIDs.

This function supports dry-run (simulation) mode. To run in dry-run mode, add
argument C<-dry_run> => 1.

Arguments (C<*> denotes required arguments):

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

=item * B<signal> => I<str> (default C<"TERM">)

Signal to use, either numeric (e.g. 1), or string (e.g. KILL).

=back

=head1 SEE ALSO

L<Process::KillTree>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

