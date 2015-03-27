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

our $VERSION = 0.02;

our @ObjectDepedencies = qw(
    Kernel::System::QueueSender
    Kernel::System::HTMLUtils
    Kernel::System::Queue
    Kernel::System::SystemAddress
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    my @Objects = qw(
        ParamObject DBObject LayoutObject ConfigObject LogObject TicketObject 
    );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $QueueSenderObject  = $Kernel::OM->Get('Kernel::System::QueueSender');
    my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');

    my %GetParam = (
        SystemAddressIDs => [ $ParamObject->GetArray( Param => 'SystemAddressIDs' ) ],
        QueueID          => $ParamObject->GetParam( Param => 'QueueID' ),
        Template         => $ParamObject->GetParam( Param => 'Template' ),
    );

    # ------------------------------------------------------------ #
    # get data 2 form
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Edit' || $Self->{Subaction} eq 'Add' ) {
        my %Subaction = (
            Edit => 'Update',
            Add  => 'Save',
        );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_MaskQueueSenderForm(
            %GetParam,
            %Param,
            Subaction => $Subaction{ $Self->{Subaction} },
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # update action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Update' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();
 
        # server side validation
        my %Errors;

        for my $Param (qw(QueueID)){
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( !@{$GetParam{SystemAddressIDs}} && !$GetParam{QueueID} ) {
            $Errors{ 'SystemAddressIDsInvalid' } = 'ServerError';
        }
        elsif ( !@{$GetParam{SystemAddressIDs}} ) {
            my %Queue = $QueueObject->QueueGet(
                ID => $GetParam{QueueID},
            );
        
            push @{$GetParam{SystemAddressIDs}}, $Queue{SystemAddressID};
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Edit';

            my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $Self->_MaskQueueSenderForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Update',
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        $QueueSenderObject->QueueSenderDelete(
            QueueID => $GetParam{QueueID},
        );

        for my $ID ( @{ $GetParam{SystemAddressIDs} } ) {
            my $Update = $QueueSenderObject->QueueSenderAdd(
                SystemAddressID => $ID,
                QueueID         => $GetParam{QueueID},
                Template        => $GetParam{Template},
            );
        }

        return $LayoutObject->Redirect( OP => "Action=AdminQueueSender" );
    }

    # ------------------------------------------------------------ #
    # insert invoice state
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Save' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # server side validation
        my %Errors;
        for my $Param (qw(QueueID)){
            if ( !$GetParam{$Param} ) {
                $Errors{ $Param . 'Invalid' } = 'ServerError';
            }
        }

        if ( !@{$GetParam{SystemAddressIDs}} && !$GetParam{QueueID} ) {
            $Errors{ 'SystemAddressIDsInvalid' } = 'ServerError';
        }
        elsif ( !@{$GetParam{SystemAddressIDs}} ) {
            my %Queue = $QueueObject->QueueGet(
                ID => $GetParam{QueueID},
            );
        
            push @{$GetParam{SystemAddressIDs}}, $Queue{SystemAddressID};
        }

        if ( %Errors ) {
            $Self->{Subaction} = 'Add';

            my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $Self->_MaskQueueSenderForm(
                %GetParam,
                %Param,
                %Errors,
                Subaction => 'Save',
            );
            $Output .= $LayoutObject->Footer();
            return $Output;
        }

        for my $ID ( @{ $GetParam{SystemAddressIDs} } ) {
            $QueueSenderObject->QueueSenderAdd(
                SystemAddressID => $ID,
                QueueID         => $GetParam{QueueID},
                Template        => $GetParam{Template},
            );
        }

        return $LayoutObject->Redirect( OP => "Action=AdminQueueSender" );
    }

    elsif ( $Self->{Subaction} eq 'Delete' ) {
        $QueueSenderObject->QueueSenderDelete( %GetParam );

        # send JSON response
        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => '{"Success":1}',
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # ------------------------------------------------------------ #
    # else ! print form
    # ------------------------------------------------------------ #
    else {
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_MaskQueueSenderForm();
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _MaskQueueSenderForm {
    my ( $Self, %Param ) = @_;

    my $QueueSenderObject   = $Kernel::OM->Get('Kernel::System::QueueSender');
    my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');

    if ( $Self->{Subaction} eq 'Edit' ) {
        my %QueueSender = $QueueSenderObject->QueueSenderGet( QueueID => $Param{QueueID} );

        $Param{SystemAddressIDs} = [ keys %QueueSender ] if !@{ $Param{SystemAddressIDs} || [] };

        if ( !$Param{Template} ) {
            $Param{Template} = $QueueSenderObject->QueueSenderTemplateGet( QueueID => $Param{QueueID} );
        }
    }

    if ( $Param{QueueID} ) {
        $Param{Queue} = $QueueObject->QueueLookup( QueueID => $Param{QueueID} );

        $LayoutObject->Block(
            Name => 'QueueID',
            Data => \%Param,
        );
    }
    else {
        my %Queues = $QueueObject->QueueList();

        $Param{QueueSelect} = $LayoutObject->BuildSelection(
            Data         => \%Queues,
            Name         => 'QueueID',
            Size         => 1,
            SelectedID   => $Param{QueueID},
            HTMLQuote    => 1,
            PossibleNone => 1,
            TreeView     => 1,
        );

        $LayoutObject->Block(
            Name => 'QueueSelect',
            Data => \%Param,
        );
    }

    my %SystemAddresses = $SystemAddressObject->SystemAddressList( Valid => 1 );
    my %SystemAddressesToShow;
    my %SystemAddressInfo;

    for my $AddressID ( keys %SystemAddresses ) {
        my %Info = $SystemAddressObject->SystemAddressGet(
            ID => $AddressID,
        );

        $SystemAddressesToShow{$AddressID} = sprintf "%s - %s", $Info{Realname}, $Info{Name};
        $SystemAddressInfo{ $Info{Name} }  = $Info{Realname};
    }

    $Param{SystemAddressSelect} = $LayoutObject->BuildSelection(
        Data       => \%SystemAddressesToShow,
        Name       => 'SystemAddressIDs',
        Size       => 10,
        Multiple   => 1,
        SelectedID => $Param{SystemAddressIDs},
    );

    if ( $Self->{Subaction} ne 'Edit' && $Self->{Subaction} ne 'Add' ) {

        my %QueueSenderList = $QueueSenderObject->QueueSenderQueueList();
  
        if ( !%QueueSenderList ) {
            $LayoutObject->Block(
                Name => 'NoQueueSenderFound',
            );
        }

        for my $Queue ( sort keys %QueueSenderList ) {
            my %Row = %Param;

            my %QueueSender = $QueueSenderObject->QueueSenderGet(
                QueueID => $QueueSenderList{$Queue},
            );

            $Row{Queue}   = $Queue;
            $Row{QueueID} = $QueueSenderList{$Queue};

            $Row{Template} = $QueueSenderObject->QueueSenderTemplateGet(
                QueueID => $QueueSenderList{$Queue},
            );

            $LayoutObject->Block(
                Name => 'QueueSenderRow',
                Data => \%Row,
            );

            for my $Sender ( sort values %QueueSender ) {
                $LayoutObject->Block(
                    Name => 'Sender',
                    Data => {
                        Sender   => $Sender,
                        Realname => $SystemAddressInfo{$Sender} || '',
                    },
                );
            }
        }
    }

    $Param{SubactionName} = 'Update';
    $Param{SubactionName} = 'Save' if $Self->{Subaction} && $Self->{Subaction} eq 'Add';

    my $TemplateFile = 'AdminQueueSenderList';
    $TemplateFile = 'AdminQueueSenderForm' if $Self->{Subaction};

    return $LayoutObject->Output(
        TemplateFile => $TemplateFile,
        Data         => \%Param
    );
}

1;
