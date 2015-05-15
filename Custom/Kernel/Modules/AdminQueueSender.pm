# --
# Kernel/Modules/AdminQueueSender.pm - administration of queue senders
# Copyright (C) 2014 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminQueueSender;

use strict;
use warnings;

use Kernel::System::QueueSender;
use Kernel::System::HTMLUtils;
use Kernel::System::Queue;
use Kernel::System::SystemAddress;

our $VERSION = 0.01;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    my @Objects = qw(
        ParamObject DBObject LayoutObject ConfigObject LogObject TicketObject 
    );
    for my $Needed (@Objects) {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }

    # create needed objects
    $Self->{QueueSenderObject}   = Kernel::System::QueueSender->new(%Param);
    $Self->{QueueObject}         = Kernel::System::Queue->new(%Param);
    $Self->{SystemAddressObject} = Kernel::System::SystemAddress->new(%Param);

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my %GetParam = (
        SystemAddressIDs => [ $Self->{ParamObject}->GetArray( Param => 'SystemAddressIDs' ) ],
        QueueID          => $Self->{ParamObject}->GetParam( Param => 'QueueID' ),
        Template         => $Self->{ParamObject}->GetParam( Param => 'Template' ),
    );

    # ------------------------------------------------------------ #
    # get data 2 form
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Edit' || $Self->{Subaction} eq 'Add' ) {
        my %Subaction = (
            Edit => 'Update',
            Add  => 'Save',
        );

        my $Output       = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_MaskQueueSenderForm(
            %GetParam,
            %Param,
            Subaction => $Subaction{ $Self->{Subaction} },
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # update action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Update' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();
 
        # server side validation
        my %Errors;

        for my $Param (qw(QueueID)){
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( !@{$GetParam{SystemAddressIDs}} ) {
            $Errors{ 'SystemAddressIDsInvalid' } = 'ServerError';
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Edit';

            my $Output = $Self->{LayoutObject}->Header();
            $Output .= $Self->{LayoutObject}->NavigationBar();
            $Output .= $Self->_MaskQueueSenderForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Update',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }

        $Self->{QueueSenderObject}->QueueSenderDelete(
            QueueID => $GetParam{QueueID},
        );

        for my $ID ( @{ $GetParam{SystemAddressIDs} } ) {
            my $Update = $Self->{QueueSenderObject}->QueueSenderAdd(
                SystemAddressID => $ID,
                QueueID         => $GetParam{QueueID},
                Template        => $GetParam{Template},
            );
        }

        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminQueueSender" );
    }

    # ------------------------------------------------------------ #
    # insert invoice state
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Save' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        # server side validation
        my %Errors;
        for my $Param (qw(QueueID)){
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( !@{$GetParam{SystemAddressIDs}} ) {
            $Errors{ 'SystemAddressIDsInvalid' } = 'ServerError';
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Add';

            my $Output = $Self->{LayoutObject}->Header();
            $Output .= $Self->{LayoutObject}->NavigationBar();
            $Output .= $Self->_MaskQueueSenderForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Save',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }

        for my $ID ( @{ $GetParam{SystemAddressIDs} } ) {
            $Self->{QueueSenderObject}->QueueSenderAdd(
                SystemAddressID => $ID,
                QueueID         => $GetParam{QueueID},
                Template        => $GetParam{Template},
            );
        }

        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminQueueSender" );
    }

    elsif ( $Self->{Subaction} eq 'Delete' ) {
        $Self->{QueueSenderObject}->QueueSenderDelete( %GetParam );
        return $Self->{LayoutObject}->Redirect( OP => "Action=AdminQueueSender" );
    }

    # ------------------------------------------------------------ #
    # else ! print form
    # ------------------------------------------------------------ #
    else {
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_MaskQueueSenderForm();
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
}

sub _MaskQueueSenderForm {
    my ( $Self, %Param ) = @_;

    if ( $Self->{Subaction} eq 'Edit' ) {
        my %QueueSender = $Self->{QueueSenderObject}->QueueSenderGet( QueueID => $Param{QueueID} );

        $Param{SystemAddressIDs} = [ keys %QueueSender ] if !$Param{SystemAddressIDs};

        if ( !$Param{Template} ) {
            $Param{Template} = $Self->{QueueSenderObject}->QueueSenderTemplateGet( QueueID => $Param{QueueID} );
        }
    }

    if ( $Param{QueueID} ) {
        $Param{Queue} = $Self->{QueueObject}->QueueLookup( QueueID => $Param{QueueID} );

        $Self->{LayoutObject}->Block(
            Name => 'QueueID',
            Data => \%Param,
        );
    }
    else {
        my %Queues = $Self->{QueueObject}->QueueList();

        $Param{QueueSelect} = $Self->{LayoutObject}->BuildSelection(
            Data         => \%Queues,
            Name         => 'QueueID',
            Size         => 1,
            SelectedID   => $Param{QueueID},
            HTMLQuote    => 1,
            PossibleNone => 1,
            TreeView     => 1,
        );

        $Self->{LayoutObject}->Block(
            Name => 'QueueSelect',
            Data => \%Param,
        );
    }

    my %SystemAddresses = $Self->{SystemAddressObject}->SystemAddressList( Valid => 1 );
    my %SystemAddressesToShow;

    for my $AddressID ( keys %SystemAddresses ) {
        my %Info = $Self->{SystemAddressObject}->SystemAddressGet(
            ID => $AddressID,
        );

        $SystemAddressesToShow{$AddressID} = sprintf "%s - %s", $Info{Realname}, $Info{Name};
    }

    $Param{SystemAddressSelect} = $Self->{LayoutObject}->BuildSelection(
        Data       => \%SystemAddressesToShow,
        Name       => 'SystemAddressIDs',
        Size       => 10,
        Multiple   => 1,
        SelectedID => $Param{SystemAddressIDs},
    );

    if ( $Self->{Subaction} ne 'Edit' && $Self->{Subaction} ne 'Add' ) {

        my %QueueSenderList = $Self->{QueueSenderObject}->QueueSenderQueueList();
  
        if ( !%QueueSenderList ) {
            $Self->{LayoutObject}->Block(
                Name => 'NoQueueSenderFound',
            );
        }

        for my $Queue ( sort keys %QueueSenderList ) {
            my %Row = %Param;

            my %QueueSender = $Self->{QueueSenderObject}->QueueSenderGet(
                QueueID => $QueueSenderList{$Queue},
            );

            $Row{Queue}   = $Queue;
            $Row{QueueID} = $QueueSenderList{$Queue};
            $Row{Sender}  = join ', ', sort values %QueueSender;

            $Self->{LayoutObject}->Block(
                Name => 'QueueSenderRow',
                Data => \%Row,
            );
        }
    }

    $Param{SubactionName} = 'Update';
    $Param{SubactionName} = 'Save' if $Self->{Subaction} && $Self->{Subaction} eq 'Add';

    my $TemplateFile = 'AdminQueueSenderList';
    $TemplateFile = 'AdminQueueSenderForm' if $Self->{Subaction};

    return $Self->{LayoutObject}->Output(
        TemplateFile => $TemplateFile,
        Data         => \%Param
    );
}

1;
