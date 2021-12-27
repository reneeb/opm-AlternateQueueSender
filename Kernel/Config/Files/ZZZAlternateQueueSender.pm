package Kernel::Config::Files::ZZZAlternateQueueSender;

use strict;
use warnings;

use List::Util qw(first);

use Kernel::System::TemplateGenerator;

our $ObjectManagerDisabled = 1;

$Kernel::Loaded{__PACKAGE__ . ""} = 0;

sub Load {
    no warnings 'redefine';

    return if $Kernel::Loaded{__PACKAGE__ . ""};

    # disable redefine warnings in this scope
    no warnings 'redefine';

    my $OrigCode = *Kernel::System::TemplateGenerator::Sender{CODE};

    *Kernel::System::TemplateGenerator::Sender = sub {
        my ($Self, %Param) = @_;

        my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
        my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

        my $Action   = $ParamObject->GetParam( Param => 'Action' ) || '';
        my $TicketID = $ParamObject->GetParam( Param => 'TicketID' ) || '';
        my $UserID   = $LayoutObject->{UserID};

        my $Sender;
        if ( first { 'AgentTicket' . $_ eq $Action } qw(Bounce Forward Compose EmailOutbound) ) {
            $Sender = $ParamObject->GetParam( Param => 'From' ) || '';

            # check if it is a valid queue sender
            my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
            my $QueueSenderObject   = $Kernel::OM->Get('Kernel::System::QueueSender');
            my $UtilsObject         = $Kernel::OM->Get('Kernel::System::QueueSender::Utils');
            my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');

            my %Queue = $QueueObject->QueueGet(
                ID => $Param{QueueID},
            );

            my $Template = $QueueSenderObject->QueueSenderTemplateGet(
                QueueID => $Param{QueueID},
            );

            my $TemplateAddress = $QueueSenderObject->QueueSenderTemplateAddressGet(
                QueueID => $Param{QueueID},
            );

            my %ValidQueueSender;
            if ( $Template ) {
                $Template = $UtilsObject->ReplaceMacros(
                    Template => $Template,
                    TicketID => $TicketID,
                    UserID   => $UserID,
                );
            }

            if ( $TemplateAddress ) {
                $TemplateAddress = $UtilsObject->ReplaceMacros(
                    Template => $TemplateAddress,
                    TicketID => $TicketID,
                    UserID   => $UserID,
                );

                if ( $TemplateAddress && $TemplateAddress !~ m{\A\@} ) {

                    $ValidQueueSender{$TemplateAddress} = 1;

                    if ( $Template && $TemplateAddress ) {
                        my $TmpAddress = sprintf q~"%s" <%s>~, $Template, $TemplateAddress;
                        $ValidQueueSender{$TmpAddress} = 1;
                    }
                }
            }

            my %List = $QueueSenderObject->QueueSenderGet(
                QueueID => $Param{QueueID},
            );

            for my $ID ( keys %List, $Queue{SystemAddressID} ) {
                my %Address = $SystemAddressObject->SystemAddressGet(
                    ID => $ID,
                );

                next if !$Address{ValidID} || $Address{ValidID} != 1;

                my $Address = $Address{Realname} ?
                    (sprintf q~"%s" <%s>~, $Address{Realname}, $Address{Name}) :
                    $Address{Name};

                if ( $Template ) {
                    $Address =  sprintf q~"%s" <%s>~, $Template, $Address{Name};
                }

                $ValidQueueSender{$Address} = 1;
            }

            $Sender = '' if !$ValidQueueSender{$Sender};
        }

        if ( !$Sender ) {
            $Sender = $Self->$OrigCode( %Param );
        }

        return $Sender;
    };

    $Kernel::Loaded{__PACKAGE__ . ""} = 1;
}

1;
