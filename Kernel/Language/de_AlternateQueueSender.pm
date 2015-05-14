# --
# Kernel/Language/de_AlternateQueueSender.pm - the german translation of AlternateQueueSender
# Copyright (C) 2014 Perl-Services, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_AlternateQueueSender;

use strict;
use warnings;

use utf8;

our $VERSION = '0.01';

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    $Lang->{'Add Queuesender'}        = 'Neue Queue <-> Sender';
    $Lang->{'Add/Change QueueSender'} = 'Alternative Queue-Absender hinzufügen/ändern';
    $Lang->{'QueueSender Management'} = 'Alternative Queue-Absender verwalten';
    $Lang->{'edit'}                   = 'bearbeiten';
    $Lang->{'Template for Realname'}  = 'Template für den Anzeigenamen';

    return 1;
}

1;
