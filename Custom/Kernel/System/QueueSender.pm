# --
# Copyright (C) 2014 - 2016 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::QueueSender;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::Log
    Kernel::System::DB
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

=item QueueSenderAdd()

to add a news 

    my $ID = $QueueSenderObject->QueueSenderAdd(
        QueueID         => 123,
        SystemAddressID => 1,
    );

=cut

sub QueueSenderAdd {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    for my $Needed (qw(QueueID SystemAddressID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # insert queue address
    return if !$DBObject->Do(
        SQL => 'INSERT INTO ps_queue_sender (queue_id, sender_address_id, template, template_address) VALUES (?,?,?,?)',
        Bind => [
            \$Param{QueueID},
            \$Param{SystemAddressID},
            \$Param{Template},
            \$Param{TemplateAddress},
        ],
    );

    # get new sender id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT MAX(id) FROM ps_queue_sender WHERE queue_id = ? AND sender_address_id = ?',
        Bind  => [ \$Param{QueueID}, \$Param{SystemAddressID} ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    $LogObject->Log(
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

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need QueueID!',
        );
        return;
    }

    # sql
    return if !$DBObject->Prepare(
        SQL  => 'SELECT qs.queue_id, sender_address_id, value0, qs.template, qs.template_address FROM ps_queue_sender qs '
            . '    INNER JOIN system_address sa ON qs.sender_address_id = sa.id WHERE qs.queue_id = ?',
        Bind => [ \$Param{QueueID} ],
    );

    my %QueueSender;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $QueueSender{$Data[1]} = $Data[2];
    }

    return %QueueSender;
}

=item QueueSenderTemplateGet()

Returns the template for a given queue.

    my $Template = $Object->QueueSenderTemplateGet(
        QueueID => 123,
    );

=cut

sub QueueSenderTemplateGet {
    my ($Self, %Param) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need QueueID!',
        );
        return;
    }

    # sql
    return if !$DBObject->Prepare(
        SQL  => 'SELECT qs.template FROM ps_queue_sender qs '
            . '    WHERE qs.queue_id = ?',
        Bind  => [ \$Param{QueueID} ],
        Limit => 1,
    );

    my $Template;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Template = $Data[0];
    }

    return $Template;
}

=item QueueSenderTemplateAddressGet()

Returns the template for a given queue.

    my $Template = $Object->QueueSenderTemplateAddressGet(
        QueueID => 123,
    );

=cut

sub QueueSenderTemplateAddressGet {
    my ($Self, %Param) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need QueueID!',
        );
        return;
    }

    # sql
    return if !$DBObject->Prepare(
        SQL  => 'SELECT qs.template_address FROM ps_queue_sender qs '
            . '    WHERE qs.queue_id = ?',
        Bind  => [ \$Param{QueueID} ],
        Limit => 1,
    );

    my $Template;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Template = $Data[0];
    }

    return $Template;
}

=item QueueSenderDelete()

deletes a news entry. Returns 1 if it was successful, undef otherwise.

    my $Success = $QueueSenderObject->QueueSenderDelete(
        QueueID => 123,
    );

=cut

sub QueueSenderDelete {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{QueueID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need QueueID!',
        );
        return;
    }

    return $DBObject->Do(
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

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT name, q.id FROM queue q INNER JOIN ps_queue_sender qs ON q.id = qs.queue_id',
    );

    my %QueueList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
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

