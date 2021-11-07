package App::Module::Cache;
use Mojo::Base 'Mojo::Cache';
use Mojo::Date;
use Storable qw(store lock_store lock_retrieve);
use Hash::Merge;

has db      => sub {};
has db_path => sub {};
has expire  => sub {};
has merger  => sub {Hash::Merge->new('LEFT_PRECEDENT')};

sub init {
	my $self = shift;
	store({}, $self->db_path) unless(-f $self->db_path);
	$self;
}

sub get {
	my $self = shift;
	my $key  = shift;
	my $db   = $self->read();
	$db->{$key} && $db->{$key}->{'data'} ? $db->{$key}->{'data'} : undef;
}

sub set {
	my $self = shift;
	return undef if( @_ % 2 );
	my $db    = $self->read();
	my %hash  = @_;
	my $epoch = $self->expire ? Mojo::Date->new(time + $self->expire)->epoch : undef;
	my $hash_ref = {};
	for my $key ( keys %hash ){
		$hash_ref->{$key}->{'data'} = $hash{$key};
		$hash_ref->{$key}->{'expire'} = $epoch if ($epoch);
	}
	$self->db($self->merger->merge($hash_ref, $db))->save();
	$self;
}

sub list {
	my $self = shift;
	my $opts = shift;
	my $db   = $self->read();
	return [] unless $db;
	my @list = ();
	for my $key ( sort keys %{$db} ) {
		push @list, { key => $key, value => $db->{$key} };
	}
	$opts && $opts->{'count'} ? scalar @list : \@list;
}

sub remove {
	my $self = shift;
	my $key  = shift;
	return undef unless $key;
	my $db   = $self->read();
	delete $db->{$key};
	$self->db($db)->save();
	$self;
}

sub read {
	my $self = shift;
	my $hash  = {};
	my $epoch = Mojo::Date->new(time)->epoch;
	my $db    = lock_retrieve( $self->db_path() );
	if( $db && ref $db eq 'HASH' ) {
		for my $key (keys %{$db}) {
			if(
				$db->{$key}->{'expire'} &&
				$db->{$key}->{'expire'} > $epoch
			) {
				$hash->{$key} = $db->{$key};
			}
			elsif (!$db->{$key}->{'expire'}) {
				$hash->{$key} = $db->{$key};
			}
		}
		$self->db($hash)->save();
	}
	return %$hash ? $hash : undef;
}

sub save {
	my $self = shift;
	lock_store( $self->db => $self->db_path() );
	$self->db(undef);
	$self;
}

1;
