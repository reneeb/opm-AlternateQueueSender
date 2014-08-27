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

use Kernel::System::Encode;
use Kernel::System::Ticket;
use Kernel::System::Time;
use Kernel::System::DB;
use Kernel::System::Queue;
use Kernel::System::QueueSender;
use Kernel::System::SystemAddress;

our $VERSION = 0.01;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (
        qw(MainObject ConfigObject LogObject LayoutObject ParamObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{EncodeObject}        = $Param{EncodeObject} || Kernel::System::Encode->new( %{$Self} );
    $Self->{TimeObject}          = $Param{TimeObject}   || Kernel::System::Time->new( %{$Self} );
    $Self->{DBObject}            = $Param{DBObject}     || Kernel::System::DB->new( %{$Self} );
    $Self->{QueueObject}         = $Param{QueueObject}  || Kernel::System::Queue->new( %{$Self} );
    $Self->{QueueSenderObject}   = Kernel::System::QueueSender->new( %{$Self} );
    $Self->{SystemAddressObject} = Kernel::System::SystemAddress->new( %{$Self} );

    $Self->{TicketObject} = Kernel::System::Ticket->new( %{$Self} );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Param{TemplateFile} || '';
    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    my ($TicketID) = $Self->{ParamObject}->GetParam( Param => 'TicketID' );
    my %Ticket     = $Self->{TicketObject}->TicketGet(
        TicketID => $TicketID,
        UserID   => $Param{UserID},
    );

    my %List = $Self->{QueueSenderObject}->QueueSenderGet( QueueID => $Ticket{QueueID} );

    return 1 if !%List;

    my %Queue = $Self->{QueueObject}->QueueGet(
        ID => $Ticket{QueueID},
    );

    my %IDAddressMap;
    my %SenderAddresses;
    for my $ID ( keys %List, $Queue{SystemAddressID} ) {
        my %Address = $Self->{SystemAddressObject}->SystemAddressGet(
            ID => $ID,
        );

        next if !$Address{ValidID} || $Address{ValidID} != 1;

        my $Address = $Address{Realname} ? (sprintf "%s <%s>", $Address{Realname}, $Address{Name}) : $Address{Name};
        $SenderAddresses{$Address} = $Address;

        $IDAddressMap{ $ID } = $Address;
    }

    return if !%SenderAddresses;

    my %Queue = $Self->{QueueObject}->QueueGet(
        ID => $Ticket{QueueID},
    );

    my $QueueSystemAddressID = $Queue{SystemAddressID};
    my $SelectedAddress      = $IDAddressMap{ $QueueSystemAddressID };
        
    my $Select = $Self->{LayoutObject}->BuildSelection(
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
