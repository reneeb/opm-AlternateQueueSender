# --
# Kernel/Output/HTML/OutputFilterAlternateQueueSender.pm
# Copyright (C) 2014 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterAlternateQueueSender;

use strict;
use warnings;

our $VERSION = 0.02;

our @ObjectDependencies = qw(
    Kernel::System::Queue
    Kernel::System::Ticket
    Kernel::System::QueueSender
    Kernel::System::SystemAddress
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {
        UserID => $Param{UserID},
    };

    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject         = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject        = $Kernel::OM->Get('Kernel::System::Ticket');
    my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');
    my $QueueSenderObject   = $Kernel::OM->Get('Kernel::System::QueueSender');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    my ($TicketID) = $ParamObject->GetParam( Param => 'TicketID' );
    my %Ticket     = $TicketObject->TicketGet(
        TicketID => $TicketID,
        UserID   => $Self->{UserID},
    );

    my %List = $QueueSenderObject->QueueSenderGet( QueueID => $Ticket{QueueID} );

    return 1 if !%List;

    my %Queue = $QueueObject->QueueGet(
        ID => $Ticket{QueueID},
    );

    my $QueueSystemAddressID = $Queue{SystemAddressID};
    my $Template             = $QueueSenderObject->QueueSenderTemplateGet( QueueID => $Ticket{QueueID} );
    my $TemplateAddress      = $QueueSenderObject->QueueSenderTemplateAddressGet( QueueID => $Ticket{QueueID} );

    my %IDAddressMap;
    my %SenderAddresses;

    if ( $Template ) {
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');
        my %UserData   = $UserObject->GetUserData(
            UserID => $Self->{UserID},
        );

        $Template =~ s{<OTRS_TICKET_([^>]+)>}{$Ticket{$1}}xmsg;
        $Template =~ s{<OTRS_([^>]+)>}{$UserData{$1}}xsmg;
    }

    if ( $TemplateAddress ) {
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');
        my %UserData   = $UserObject->GetUserData(
            UserID => $Self->{UserID},
        );

        $TemplateAddress =~ s{<OTRS_TICKET_([^>]+)>}{$Ticket{$1}}xmsg;
        $TemplateAddress =~ s{<OTRS_([^>]+)>}{$UserData{$1}}xsmg;

        $SenderAddresses{$TemplateAddress} = $TemplateAddress;

        if ( $Template ) {
            $TemplateAddress = sprintf "%s <%s>", $Template, $TemplateAddress;
            $SenderAddresses{$TemplateAddress} = $TemplateAddress;
        }
    }

    for my $ID ( keys %List, $Queue{SystemAddressID} ) {
        my %Address = $SystemAddressObject->SystemAddressGet(
            ID => $ID,
        );

        next if !$Address{ValidID} || $Address{ValidID} != 1;

        my $Address = $Address{Realname} ? (sprintf "%s <%s>", $Address{Realname}, $Address{Name}) : $Address{Name};
        $SenderAddresses{$Address} = $Address;

        if ( $Template ) {
            $Address =  sprintf "%s <%s>", $Template, $Address{Name};
            $SenderAddresses{$Address} = $Address;
        }

        $IDAddressMap{ $ID } = $Address;
    }

    return if !%SenderAddresses;

    my $SelectedAddress      = $IDAddressMap{ $QueueSystemAddressID };
        
    my $Select = $LayoutObject->BuildSelection(
        Data          => \%SenderAddresses,
        Name          => 'From',
        Size          => 1,
        SelectedValue => $SelectedAddress,
    );

    ${ $Param{Data} } =~ s{(
        <div \s+ class="Field"> \s+
            [^<]*? <input [^>]+ name="From" [^>]+ > \s+
            [^<]*?
        </div>
    )}{<div class="Field">$Select</div>}smx;

    return ${ $Param{Data} };
}

1;
