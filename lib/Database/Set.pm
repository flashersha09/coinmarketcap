package Database::Set;

use Mojo::Base -strict;

sub new {
	my ($class, $data) = @_;

	if (ref $data ne 'ARRAY') {
		$data = [];
	}

	return bless $data, $class;
}

sub first {
	my ($self) = @_;
	return $self->[0];
}

sub last {
	my ($self) = @_;
	return $self->[-1];
}

sub count {
	my ($self) = @_;
	return scalar @{$self};
}

sub to_map {
	my ($self, $key) = @_;
	$key ||= 'id';
	return { map { $_->{$key} => $_ } @{$self} };
}

sub header {
	my ($self, $key) = @_;
	if (my $row = $self->first) {
		return sort keys %{$row};
	}
	return;
}

sub column {
	my ($self, $key) = @_;
	return [ map { $_->{$key} } @{$self} ];
}

sub each {
	my ($self, $cb) = @_;
	foreach my $item (@{$self}) {
		$_ = $item;
		$cb->($item);
	}
	return $self;
}

sub every {
	my ($self, $cb) = @_;
	my @result;
	foreach my $item (@{$self}) {
		$_ = $item;
		push @result, $cb->($item);
	}
	return \@result;
}

sub iterator {
	my ($self) = @_;
	my $cnt = 0;
	return sub { $self->[ $cnt++ ] };
}

sub sum {
	my ($self, $field, $value) = @_;
	my $sum = 0;
	foreach my $item (@{$self}) {
		next unless $item->{$field};
		if (defined $value) {
			$sum++ if $item->{$field} eq $value;
		} else {
			$sum += $item->{$field};
		}
	}
	return $sum;
}

1;