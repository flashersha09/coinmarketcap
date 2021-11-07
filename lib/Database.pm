package Database;

use Mojo::Base -base;

use DBI;
use SQL::Abstract::More;
use Carp qw(confess);

use Database::Set;

has 'dbname';
has log => '';
has dbuser => '';
has dbpass => '';
has dbport => '';
has dbhost => '';

sub dbh {
	my ($self) = @_;

	my $dbh = $self->{_dbh};

	return $dbh if $dbh;

	return $self->{_dbh} = $dbh = $self->_connect();
};

sub error_detail {
	my ($self) = @_;

	my $err = $self->dbh->errstr() || '';

	my @errstr = split /\n/, $err;

	foreach my $line (@errstr) {
		if ( my ($error) = $line =~ /^DETAIL:\s+(.*)$/ ) {
			return $error;
		}
	}

	return;
}

sub _connect {
	my ($self) = @_;

	my $dsn = 'dbi:Pg:dbname=' . $self->dbname;

	if ($self->dbhost) {
		$dsn .= ';host=' . $self->dbhost;
	}

	if ($self->dbport) {
		$dsn .= ';port=' . $self->dbport;
	}

	my $dbh = DBI->connect(
		$dsn, $self->dbuser, $self->dbpass, { AutoCommit => 1, PrintError => 0 },
	) or confess $DBI::errstr;

	$dbh->{ShowErrorStatement}  = 1;
	$dbh->{RaiseError}          = 1;
	$dbh->{AutoInactiveDestroy} = 1;
	$dbh->{HandleError}         = sub { confess(shift) };

	return $dbh;
}

sub reconnect {
	my ($self) = @_;
	$self->{_dbh} = undef;
	$self->dbh;
	return;
}

sub last_insert_id {
	my ($self, $table) = @_;
	return $self->dbh->last_insert_id(undef, undef, $table, undef);
}

sub begin_work {
	my ($self) = @_;
	return $self->dbh->begin_work;
}

sub commit {
	my ($self) = @_;
	return $self->dbh->commit;
}

sub rollback {
	my ($self) = @_;
	return $self->dbh->rollback;
}

sub abstract {
	my ($self) = @_;

	return $self->{_sql_abstract} ||= SQL::Abstract::More->new(
		sqltrue  => 't',
		sqlfalse => 'f',
	);
}

sub build_select {
	my ($self, @query) = @_;

	my ($stmt, @bind) = $self->abstract->select(@query);

	return $stmt, @bind;
}

sub select_iterator {
	my ($self, @query) = @_;

	my ($stmt, @bind);
	if (ref $query[0] eq 'REF') {
		($stmt, @bind) = @{ ${ $query[0] } };
	} else {
		($stmt, @bind) = $self->build_select(@query);
	}

	my $sth = $self->dbh->prepare($stmt);
	$sth->execute(@bind);

	return sub {
		return $sth->fetchrow_hashref();
	};
}

sub select_query {
	my ($self, @query) = @_;

	my ($stmt, @bind);
	if (ref $query[0] eq 'REF') {
		($stmt, @bind) = @{ ${ $query[0] } };
	} else {
		($stmt, @bind) = $self->build_select(@query);
	}
	my $result = $self->dbh->selectall_arrayref($stmt, { Slice => {} }, @bind);
	return Database::Set->new($result);
}

sub count_query {
	my ($self, @query) = @_;

	my %param = @query;

	delete $param{'-order_by'};
	delete $param{'-limit'};
	delete $param{'-offset'};

	my $aggregate = '*';
	if ( $param{'-group_by'} && !ref $param{'-group_by'} ) {
		$aggregate = 'DISTINCT ' . delete $param{'-group_by'};
	} elsif ( $param{'-group_by'} ) {
		...
	}

	$param{'-columns'} = "COUNT($aggregate)";

	my ($count) = $self->selectrow_query(%param);

	return $count;
}

sub insert_query {
	my ($self, @query) = @_;

	my ($stmt, @bind) = $self->abstract->insert(@query);

	return $self->dbh->do($stmt, undef, @bind);
}

sub update_query {
	my ($self, @query) = @_;

	my ($stmt, @bind) = $self->abstract->update(@query);

	return $self->dbh->do($stmt, undef, @bind);
}

sub delete_query {
	my ($self, @query) = @_;

	my ($stmt, @bind) = $self->abstract->delete(@query);

	return $self->dbh->do($stmt, undef, @bind);
}

sub check_duplicate {
	my ($self, $table, $id, %fields) = @_;

	my ($is_duplicate) = $self->selectrow_query(
		-columns => '1',
		-from    => $table,
		-where   => { id => { '!=' => $id }, %fields },
	);

	return $is_duplicate;
}

sub selectrow_query {
	my ($self, @query) = @_;

	my ($stmt, @bind);
	if (ref $query[0] eq 'REF') {
		($stmt, @bind) = @{ ${ $query[0] } };
	} else {
		($stmt, @bind) = $self->build_select(@query);
	}

	return $self->dbh->selectrow_array($stmt, undef, @bind);
}

1;
