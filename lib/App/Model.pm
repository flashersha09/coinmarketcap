package App::Model;

use Mojo::Base -base;

use Mojo::Util qw(decamelize);
use Mojo::Date;

use List::Util qw(uniq);
use JSON;

has 'app' => sub {};
has 'view' => sub {};
has table   => sub {
	my ($self) = @_;
	return decamelize((split /::/, ref $self)[-1]);
};

has model   => sub { shift->app->model(@_) };
has db      => sub { shift->app->db(@_) };
has columns => sub { ['*'] };
has types   => sub { {} };

sub apply_types {
	my ($self, $params) = @_;

	foreach my $field ( keys %{$self->types} ) {
		next unless defined $params->{$field};
		my $type = $self->types->{$field};
		if ($type eq 'json') {
			$params->{$field} = $params->{$field} ? to_json($params->{$field}) : undef;
		}
		elsif ($type eq 'datetime_iso') {
			# skip
		}
		elsif ($type eq 'boolean') {
			$params->{$field} = $params->{$field} ? 'true' : 'false';
		}
		elsif ($type eq 'array') {
			$params->{$field} = '{' . ( join q{,}, @{ from_json($params->{$field}) } ) . '}';
		}

	}

	return $params;
}

sub extract_types {
	my ($self, $params) = @_;

	foreach my $field ( keys %{$self->types} ) {
		my $type = $self->types->{$field};

		if ($type eq 'json') {
			$params->{$field} = $params->{$field} ? from_json($params->{$field}) : undef;
		}
		elsif ($type eq 'boolean') {
			$params->{$field} = $params->{$field} ? 1 : 0;
		}
		elsif ($type eq 'array') {
			$params->{$field} = $params->{$field};
		}
	}

	return $params;
}

sub prepare_types {
	my ($self, $field) = @_;

	my $types = $self->types;
	if ( $field =~ m/(.+)\s(asc|desc)/i ) {
		if ( exists $types->{$1} && $types->{$1} eq 'enum' ) {
			$field = join q{ }, ($1 .'::text', $2);
		}
	}
	return $field;
}

sub create {
	my ($self, $params) = @_;

	return unless ref $params eq 'HASH';

	my $res = $self->db->insert_query(
		-into   => $self->table,
		-values => $self->apply_types($params),
	);

	return $self->db->last_insert_id($self->table);
}

sub get {
	my ($self, $id, $opts) = @_;
	$opts //= {};

	return unless $id;

	my $where = ref $id eq 'HASH' ? $id : { id => $id };

	my @columns = @{$self->columns};

	if ( $opts->{add_columns} && ref $opts->{add_columns} eq 'ARRAY' ) {
		push @columns, @{ $opts->{add_columns} };
		@columns = uniq @columns;
	}

	my $result = $self->db->select_query(
		-columns => \@columns,
		-from    => $self->view || $self->table,
		-where   => $where,
		-limit   => 1,
	)->first;

	$result = $self->extract_types($result)
		if $result;

	if ( $result && $opts->{is_recursive} ) {
		$self->expand( $result, is_recursive => 1 );
	}

	return $result;
}

sub get_list {
	my ( $self, $where, $opts ) = @_;

	$where //= {};
	$opts //= {};
	return unless ref $where eq 'HASH';

	my %query = (
		-columns => $self->columns,
		-from    => $self->view || $self->table,
		-where   => $where,
	);

	if ( $opts->{add_columns} && ref $opts->{add_columns} eq 'ARRAY' ) {
		push @{ $query{'-columns'} }, @{ $opts->{add_columns} };
		@{ $query{'-columns'} } = uniq @{ $query{'-columns'} };
	}

	if ( $opts->{order_by} ) {
		$query{'-order_by'} = $self->prepare_types( $opts->{order_by} );
	}

	if ( $opts->{group_by} ) {
		$query{'-group_by'} = $self->prepare_types( $opts->{group_by} );
	}

	if ( $opts->{limit} ) {
		$query{'-limit'} = int $opts->{limit};

		if ( $opts->{offset} ) {
			$query{'-offset'} = int $opts->{offset};
		}
	}

	if ( $opts->{count} ) {
		return $self->db->count_query(%query);
	}

	my $result = $self->db->select_query(%query);

	$result->each(sub { $self->extract_types($_) });

	if ( $opts->{expand} ) {
		$self->expand( $_, is_recursive => 1 ) for @{$result};
	}

	return $result;
}

sub details {
	my ($self, $id) = @_;

	my $details = $self->get($id);

	$self->expand($details, is_recursive => 1);

	return $details;
}

sub update {
	my ($self, $id, $params) = @_;

	return unless $id;
	return unless ref $params eq 'HASH';

	my $where = ref $id eq 'HASH' ? $id : { id => $id };

	$params = $self->apply_types($params);

	return $self->db->update_query(
		-table => $self->table,
		-set   => $params,
		-where => $where,
	);
}

sub delete {
	my ($self, $id) = @_;

	return unless $id;

	my $where = ref $id eq 'HASH' ? $id : { id => $id };

	return $self->db->delete_query(
		-from  => $self->table,
		-where => $where,
	);
}

sub expand {
	my ($self, $row, %args) = @_;

	if ( $self->can('relationship') ) {
		my $deps = $self->relationship;
		for my $key (keys %{$deps}) {
			$row->{$key} = $self->app->model( $deps->{$key} )->get($row->{$key});
			if ($args{is_recursive}) {
				$self->app->model( $deps->{$key} )->expand($row->{$key}, is_recursive => 1);
			}
		}
	}

	return $row;
}

1;
