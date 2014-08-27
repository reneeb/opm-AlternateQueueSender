# --
# Kernel/System/QueueSender.pm - All QueueSender related functions should be here eventually
# Copyright (C) 2014 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::QueueSender;

use strict;
use warnings;

our $VERSION = 0.01;

=head1 NAME

Kernel::System::QueueSender - backend for queue sender 

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::QueueSender;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $QueueSenderObject = Kernel::System::QueueSender->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
        EncodeObject => $EncodeObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(DBObject ConfigObject MainObject LogObject EncodeObject TimeObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item QueueSenderAdd()

to add a news 

    my $ID = $QueueSenderObject->QueueSenderAdd(
        QueueID         => 123,
        SystemAddressID => 1,
    );

=cut

sub QueueSenderAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(QueueID SystemAddressID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # insert queue address
    return if !$Self->{DBObject}->Do(
        SQL => 'INSERT INTO ps_queue_sender (queue_id, sender_address_id) VALUES (?,?)',
        Bind => [
            \$Param{QueueID},
            \$Param{SystemAddressID},
        ],
    );

    # get new invoice id
    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT MAX(id) FROM ps_queue_sender WHERE queue_id = ? AND sender_address_id = ?',
        Bind  => [ \$Param{QueueID}, \$Param{SystemAddressID} ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => "QueueSender '$ID' created successfully!",
    );

    return $ID;
}


=item QueueSenderGet()

returns a hash with news data

    my %QueueSenderData = $QueueSenderObject->QueueSenderGet( QueueID => 2 );

This returns something like:

    %QueueSenderData = (
        1  => 'info@example.tld',
        11 => 'test@example.tld',
    );

=cut

sub QueueSenderGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need QueueID!',
        );
        return;
    }

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL  => 'SELECT qs.queue_id, sender_address_id, value0 FROM ps_queue_sender qs '
            . '    INNER JOIN system_address sa ON qs.sender_address_id = sa.id WHERE qs.queue_id = ?',
        Bind => [ \$Param{QueueID} ],
    );

    my %QueueSender;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        $QueueSender{$Data[1]} = $Data[2];
    }

    return %QueueSender;
}

=item QueueSenderDelete()

deletes a news entry. Returns 1 if it was successful, undef otherwise.

    my $Success = $QueueSenderObject->QueueSenderDelete(
        QueueID => 123,
    );

=cut

sub QueueSenderDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need QueueID!',
        );
        return;
    }

    return $Self->{DBObject}->Do(
        SQL  => 'DELETE FROM ps_queue_sender WHERE queue_id = ?',
        Bind => [ \$Param{QueueID} ],
    );
}

=item QueueSenderQueueList()

Get a list of all queues that have other senders configured

    my %Queues = $QueueSenderObject->QueueSenderQueueList;

=cut

sub QueueSenderQueueList {
    my ( $Self, %Param ) = @_;

    return if !$Self->{DBObject}->Prepare(
        SQL  => 'SELECT name, q.id FROM queue q INNER JOIN ps_queue_sender qs ON q.id = qs.queue_id',
    );

    my %QueueList;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $QueueList{ $Row[0] } = $Row[1];
    }

    return %QueueList;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

