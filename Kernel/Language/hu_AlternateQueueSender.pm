# --
# Kernel/Language/hu_AlternateQueueSender.pm - the Hungarian translation of AlternateQueueSender
# Copyright (C) 2015 - 2016 Perl-Services, http://www.perl-services.de
# Copyright (C) 2016 Balázs Úr, http://www.otrs-megoldasok.hu
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::hu_AlternateQueueSender;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Custom/Kernel/Output/HTML/Templates/Standard/AdminQueueSenderForm.tt
    $Lang->{'Queue Sender Management'} = 'Várólistaküldő kezelése';
    $Lang->{'Actions'} = 'Műveletek';
    $Lang->{'Go to overview'} = 'Ugrás az áttekintőhöz';
    $Lang->{'Add/Change Queue Sender'} = 'Várólistaküldő hozzáadása vagy megváltoztatása';
    $Lang->{'Queue'} = 'Várólista';
    $Lang->{'Queue is mandatory.'} = 'A várólista kötelező.';
    $Lang->{'Sender'} = 'Küldő';
    $Lang->{'Please select sender addresses.'} = 'Válasszon küldőcímeket.';
    $Lang->{'Alternative Address'} = 'Alternatív cím';
    $Lang->{'Make Default Address'} = 'Legyen alapértelmezett cím';
    $Lang->{'Alternative Real Name'} = 'Alternatív teljes név';
    $Lang->{'Save'} = 'Mentés';
    $Lang->{'or'} = 'vagy';
    $Lang->{'Cancel'} = 'Mégse';

    # Custom/Kernel/Output/HTML/Templates/Standard/AdminQueueSenderList.tt
    $Lang->{'Add Queue Sender'} = 'Várólistaküldő hozzáadása';
    $Lang->{'List'} = 'Lista';
    $Lang->{'Template'} = 'Sablon';
    $Lang->{'Edit'} = 'Szerkesztés';
    $Lang->{'Edit Queue Sender'} = 'Várólistaküldő szerkesztése';
    $Lang->{'Delete'} = 'Törlés';
    $Lang->{'Delete Queue Sender'} = 'Várólistaküldő törlése';
    $Lang->{'No matches found.'} = 'Nincs találat.';
    $Lang->{'Do you really want to delete this Queue <-> Sender relations?'} =
        'Valóban törölni szeretné ezt a Várólista <-> Küldő kapcsolatot?';

    # Kernel/Config/Files/AlternateQueueSender.xml
    $Lang->{'Frontend module registration for the queue sender administration.'} =
        'Előtétprogram-modul regisztráció a várólistaküldő adminisztrálásához.';
    $Lang->{'Create and manage queue sender.'} = 'Várólistaküldő létrehozása és kezelése.';
    $Lang->{'Queue Sender'} = 'Várólistaküldő';
    $Lang->{'Module to show the queue sender dropdown.'} = 'Egy modul a várólistaküldő legördülő megjelenítéséhez.';

    return 1;
}

1;
