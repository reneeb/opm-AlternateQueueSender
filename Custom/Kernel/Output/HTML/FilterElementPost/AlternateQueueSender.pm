# --
# Copyright (C) 2014 - 2023 Perl-Services.de, https://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::AlternateQueueSender;

use strict;
use warnings;

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
    my $UtilsObject         = $Kernel::OM->Get('Kernel::System::QueueSender::Utils');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    my ($TicketID) = $ParamObject->GetParam( Param => 'TicketID' );
    my %Ticket     = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $Self->{UserID},
    );

    my %List = $QueueSenderObject->QueueSenderGet( QueueID => $Ticket{QueueID} );

    return 1 if !%List;

    my %Queue = $QueueObject->QueueGet(
        ID => $Ticket{QueueID},
    );

    my $QueueSystemAddressID = $Queue{SystemAddressID};
    my $Template             = $QueueSenderObject->QueueSenderTemplateGet( QueueID => $Ticket{QueueID} );
    my $TemplateAddress      = $QueueSenderObject->QueueSenderTemplateAddressGet( QueueID => $Ticket{QueueID} );
    my $IsDefault            = $QueueSenderObject->QueueSenderIsDefault( QueueID => $Ticket{QueueID} );

    my %IDAddressMap;
    my %SenderAddresses;

    if ( $Template ) {
        $Template = $UtilsObject->ReplaceMacros(
            Template => $Template,
            Ticket   => \%Ticket,
            UserID   => $Self->{UserID},
        );
    }

    if ( $TemplateAddress ) {
        $TemplateAddress = $UtilsObject->ReplaceMacros(
            Template => $TemplateAddress,
            Ticket   => \%Ticket,
            UserID   => $Self->{UserID},
        );

        if ( $TemplateAddress && $TemplateAddress !~ m{\A\@} ) {

            $SenderAddresses{$TemplateAddress} = $TemplateAddress;

            if ( $Template && $TemplateAddress ) {
                $TemplateAddress = sprintf q~"%s" <%s>~, $Template, $TemplateAddress;
                $SenderAddresses{$TemplateAddress} = $TemplateAddress;
            }
        }
    }

    for my $ID ( keys %List, $Queue{SystemAddressID} ) {
        my %Address = $SystemAddressObject->SystemAddressGet(
            ID => $ID,
        );

        next if !$Address{ValidID} || $Address{ValidID} != 1;

        my $Address = $Address{Realname} ? (sprintf q~"%s" <%s>~, $Address{Realname}, $Address{Name}) : $Address{Name};
        $SenderAddresses{$Address} = $Address;

        if ( $Template ) {
            $Address =  sprintf q~"%s" <%s>~, $Template, $Address{Name};
            $SenderAddresses{$Address} = $Address;
        }

        $IDAddressMap{ $ID } = $Address;
    }

    return if !%SenderAddresses;

    my $SelectedAddress = $IDAddressMap{ $QueueSystemAddressID };

    if ( $TemplateAddress && $IsDefault ) {
        $SelectedAddress = $TemplateAddress;
    }
        
    my $Select = $LayoutObject->BuildSelection(
        Data          => \%SenderAddresses,
        Name          => 'From',
        Size          => 1,
        SelectedValue => $SelectedAddress,
        Class         => 'Modernize',
    );

    my $From = $LayoutObject->{LanguageObject}->Translate('From');
    ${ $Param{Data} } =~ s{(
        <label>\Q$From\E:</label> \s+
        <div \s+ class="Field"> \K
            .*?
        </div>
    )}{$Select</div>}smx;

    return 1;
}

1;
