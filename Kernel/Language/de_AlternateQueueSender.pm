# --
# Kernel/Language/de_AlternateQueueSender.pm - the German translation of AlternateQueueSender
# Copyright (C) 2015 - 2022 Perl-Services, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_AlternateQueueSender;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Custom/Kernel/Output/HTML/Templates/Standard/AdminQueueSenderForm.tt
    $Lang->{'Queue Sender Management'} = 'Alternative Queue-Absender verwalten';
    $Lang->{'Actions'} = '';
    $Lang->{'Go to overview'} = 'Zur Übersicht gehen';
    $Lang->{'Add/Change Queue Sender'} = 'Alternative Queue-Absender hinzufügen/ändern';
    $Lang->{'Queue'} = 'Queue';
    $Lang->{'Queue is mandatory.'} = '';
    $Lang->{'Sender'} = '';
    $Lang->{'Please select sender addresses.'} = '';
    $Lang->{'Template for Address'} = '';
    $Lang->{'You can use ticket variables to make the address more dynamic.'} = '';
    $Lang->{'E.g. <OTRS_TICKET_DynamicField_Project>@test.example'} = '';
    $Lang->{'Make Default Address'} = '';
    $Lang->{'Template for Real Name'} = '';
    $Lang->{'You can use user variables to make the address more dynamic.'} = '';
    $Lang->{'E.g. <OTRS_UserLastname> for <OTRS_DynamicField_Project>'} = '';
    $Lang->{'Save'} = '';
    $Lang->{'or'} = '';
    $Lang->{'Cancel'} = '';

    # Custom/Kernel/Output/HTML/Templates/Standard/AdminQueueSenderList.tt
    $Lang->{'Add Queue Sender'} = 'Neue Queue <-> Sender';
    $Lang->{'List'} = '';
    $Lang->{'Template'} = '';
    $Lang->{'Edit'} = 'Bearbeiten';
    $Lang->{'Edit Queue Sender'} = 'Queue-Absender bearbeiten';
    $Lang->{'Delete'} = '';
    $Lang->{'Delete Queue Sender'} = 'Queue-Absender löschen';
    $Lang->{'No matches found.'} = '';
    $Lang->{'Do you really want to delete this Queue <-> Sender relations?'} =
        'Wollen Sie wirkliche diese Queue-Absender löschen?';

    # Kernel/Config/Files/AlternateQueueSender.xml
    $Lang->{'Frontend module registration for the queue sender administration.'} = '';
    $Lang->{'Create and manage queue sender.'} = '';
    $Lang->{'Queue Sender'} = '';
    $Lang->{'Module to show the queue sender dropdown.'} = '';

    return 1;
}

1;
