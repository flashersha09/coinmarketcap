package App::Module::Coinmarketcap;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::Log;
use App::Module::Cache;

has app => sub {};
has log => sub {
	Mojo::Log->new( path => shift->app->config('logfiles')->{'coinmarketcap'} )
};
has api_key => sub {};
has ua => sub { Mojo::UserAgent->new() };
has api_url => sub {};
has api_rates => sub {};
has header => sub {};
has cache => sub { App::Module::Cache->new() };
has currency_default => sub {};

sub init {
	my $self = shift;
	$self->api_key( $self->app->config('coinmarketcap')->{'api_key'} );
	$self->api_url( $self->app->config('coinmarketcap')->{'api_url'} );
	$self->api_rates( $self->app->config('coinmarketcap')->{'api_rates'} );
	$self->header( {"X-CMC_PRO_API_KEY" => $self->api_key} );
	$self->cache->db_path( $self->app->config('cache')->{'db_path'} )->init();
	$self->currency_default( $self->app->config('currency')->{'default'} );
	return $self;
}

sub get_rates {
	my $self = shift;
	my $rates = $self->cache->get('rates');
	unless( $rates ) {
		my $url = $self->api_url . $self->api_rates;
		my $res = $self->ua->get( $url, $self->header )->result;
		if( $res->is_success ) {
			$rates = $self->parse($res->json);
			$self->log->info('Coinmarketcap get_rates is done');
		}
		elsif ( $res->is_error ){
			$self->log->error($res->message);
		}
		$self->cache->expire($self->app->config('cache')->{'expire'});
		$self->cache->set('rates' => $rates);
	}
	$rates;
}

sub parse {
	my $self = shift;
	my $json = shift;
	my $rates = {};
	my @rates = @{$json->{'data'}};
	for my $rate (@rates) {
		$rates->{ lc($rate->{'symbol'}) }->{ $self->currency_default } = $rate->{'quote'}->{ uc($self->currency_default) }->{'price'};
	}
	$self->log->info('Coinmarketcap parse is done');
	$rates;
}

sub calculator {
	my $self = shift;
	my $data = shift;
	my $rates = {};
	my %currencies;
	if ( $data && ref $data eq 'HASH' ) {
		for my $code_from ( keys %{$data} ) {
			my $rate_from = $data->{$code_from};
			next unless ( $rate_from && $rate_from->{ $self->currency_default } );

			$currencies{$code_from} = $rate_from;
			$currencies{ $self->currency_default }->{$code_from} = $rate_from->{ $self->currency_default };

			for my $code_to ( keys %{$data} ) {
				my $rate_to = $data->{$code_to};
				next if $code_from eq $code_to;
				next unless ( $rate_to && $rate_to->{ $self->currency_default } );
				$currencies{$code_from}->{$code_to} = $rate_from->{ $self->currency_default } / $rate_to->{ $self->currency_default };
			}
		}
	}
	return %currencies ? \%currencies : undef;
}

1;
