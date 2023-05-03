# --
# Copyright (C) 2014 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::QueueSender::Utils;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Ticket
    Kernel::System::User
    Kernel::System::CustomerUser
);

=head1 NAME

Kernel::System::QueueSender - backend for queue sender 

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}


sub ReplaceMacros {
    my ($Self, %Param) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');

    my %UserData = $UserObject->GetUserData(
        UserID => $Param{UserID},
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

    my $Template = $Param{Template} // '';
    my %Ticket   = %{ $Param{Ticket} || {} };

    if ( !%Ticket && $Param{TicketID} && $Param{UserID} ) {
        %Ticket = $TicketObject->TicketGet(
            TicketID      => $Param{TicketID},
            UserID        => $Param{UserID},
            DynamicFields => 1,
        );
    }

    $Template =~ s{<OTRS_TICKET_([^>]+)>}{
        my $OrigKey             = $1;
        my ($Key, $AllCommands) = $1 =~ m!\A ([^\s]+) ((?: \s+ \| \s+ (?:$FiltersRE))+ )!xg;

        my @Commands = split /\s*\|\s*/, $AllCommands || '';

        my $Replace = $Key ? $Ticket{$Key} : $Ticket{$OrigKey};
	$Replace //= '';

        for my $Command ( @Commands ) {
            next if !$Command;
            if ( $Command && $Filters{$Command} ) {
                $Replace = $Filters{$Command}->( $Replace );
            }
        }

        $Replace;
    }exmsg;

    if ( $Ticket{CustomerUserID} ) {
        my %CustomerData = $CustomerUserObject->CustomerUserDataGet(
            User => $Ticket{CustomerUserID},
        );

        if ( %CustomerData ) {
            $Template =~ s{<OTRS_CUSTOMER_([^>]+)>}{$CustomerData{$1}}xsmg;
        }
    }

    $Template =~ s{<OTRS_([^>]+)>}{$UserData{$1}}xsmg;
    $Template =~ s{<OTRS_([^>]+)>}{}xsmg;
    
    return $Template;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

