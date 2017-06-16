# --
# Copyright (C) 2014 - 2016 Perl-Services.de, http://www.perl-services.de/
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
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');
        my %UserData   = $UserObject->GetUserData(
            UserID => $Self->{UserID},
        );

        my %Filters = (
            lc            => sub { lc $_[0] },
            convert_chars => sub {
                my $Val = $_[0];
                my $Map = $ConfigObject->Get('Convert::Chars') || {};
                $Val =~ s{ $_ }{$Map->{$_}}g for sort keys %{$Map};
                $Val;
            },
        );

        my $FiltersRE = join '|', sort keys %Filters;

        $Template =~ s{<OTRS_TICKET_([^>]+)>}{
            my $OrigKey             = $1;
            my ($Key, $AllCommands) = $1 =~ m!\A ([^\s]+) ((?: \s+ \| \s+ (?:$FiltersRE))+ )!xg;

            my @Commands = split /\s*\|\s*/, $AllCommands;

            my $Replace = $Key ? $Ticket{$Key} : $Ticket{$OrigKey};
            for my $Command ( @Commands ) {
                if ( $Command && $Filters{$Command} ) {
                    $Replace = $Filters{$Command}->( $Replace );
                }
            }

            $Replace;
        }exmsg;

        $Template =~ s{<OTRS_([^>]+)>}{$UserData{$1}}xsmg;
        $Template =~ s{<OTRS_([^>]+)>}{}xsmg;
    }

    if ( $TemplateAddress ) {
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');
        my %UserData   = $UserObject->GetUserData(
            UserID => $Self->{UserID},
        );

        my %Filters = (
            lc            => sub { lc $_[0] },
            convert_chars => sub {
                my $Val = $_[0];
                my $Map = $ConfigObject->Get('Convert::Chars') || {};
                $Val =~ s{ $_ }{$Map->{$_}}xg for sort keys %{$Map};
                $Val;
            },
        );

        my $FiltersRE = join '|', sort keys %Filters;

        $TemplateAddress =~ s{<OTRS_TICKET_([^>]+)>}{
            my $OrigKey             = $1;
            my ($Key, $AllCommands) = $1 =~ m!\A ([^\s]+) ((?: \s+ \| \s+ (?:$FiltersRE))+ )!xg;

            my @Commands = split /\s*\|\s*/, $AllCommands;

            my $Replace = $Key ? $Ticket{$Key} : $Ticket{$OrigKey};
            for my $Command ( @Commands ) {
                if ( $Command && $Filters{$Command} ) {
                    $Replace = $Filters{$Command}->( $Replace );
                }
            }

            $Replace;
        }exmsg;

        $TemplateAddress =~ s{<OTRS_([^>]+)>}{$UserData{$1}}xsmg;
        $TemplateAddress =~ s{<OTRS_([^>]+)>}{}xsmg;

        if ( $TemplateAddress !~ m{\A\@} ) {

            $SenderAddresses{$TemplateAddress} = $TemplateAddress;

            if ( $Template && $TemplateAddress ) {
                $TemplateAddress = sprintf "%s <%s>", $Template, $TemplateAddress;
                $SenderAddresses{$TemplateAddress} = $TemplateAddress;
            }
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

    my $SelectedAddress = $IDAddressMap{ $QueueSystemAddressID };

    if ( $TemplateAddress && $IsDefault ) {
        $SelectedAddress = $TemplateAddress;
    }
        
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
