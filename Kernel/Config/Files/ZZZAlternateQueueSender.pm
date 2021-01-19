package Kernel::Config::Files::ZZZAlternateQueueSender;

use strict;
use warnings;

use List::Util qw(first);

use Kernel::System::TemplateGenerator;

our @ObjectDependencies = qw();

our $Loaded = 0;


# disable redefine warnings in this scope
sub Load {
    no warnings 'redefine';

    if ( !$Loaded ) {
        my $OrigCode = *Kernel::System::TemplateGenerator::Sender{CODE};

        *Kernel::System::TemplateGenerator::Sender = sub {
            my ($Self, %Param) = @_;

            my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
            my $Action      = $ParamObject->GetParam( Param => 'Action' );

            my $Sender;
            if ( first { 'AgentTicket' . $_ eq $Action } qw(Bounce Forward Compose EmailOutbound) ) {
                $Sender = $ParamObject->GetParam( Param => 'From' );
            }

            if ( !$Sender ) {
                $Sender = $Self->$OrigCode( %Param );
            }

            return $Sender;
        }
    }

    $Loaded++;
}

1;
