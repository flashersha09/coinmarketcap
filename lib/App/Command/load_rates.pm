package App::Command::load_rates;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Log;
use App::Module::Coinmarketcap;
use Try::Tiny;

has description => 'Import Coinmarketcap';

has log => sub {
	Mojo::Log->new( path => shift->app->config('logfiles')->{'commands'} )
};
has coinmarketcap => sub { App::Module::Coinmarketcap->new() };

sub run {
	my ($self, @args) = @_;
	my $command = shift @args;
	try {
		$self->app->db->begin_work();
		$self->coinmarketcap->app($self->app)->init();
		my $load_rates = $self->coinmarketcap->get_rates();
		my $currencies = $self->coinmarketcap->calculator($load_rates);
		my $update_rate = $self->app->model->update_rates->create({ ctime => '\NOW()' });

		while ( my($currency_code, $rates) = each %{$currencies} ) {
			my $currency_id = $self->app->model->currencies->save($currency_code);
			my $new_rate = $self->app->model->rates->create({
				currency_id => $currency_id,
				update_rate_id => $update_rate,
				rates => $rates,
				ctime => '\NOW()',
			});
		}

		$self->log->info('Command load_rates is done.');
		$self->app->db->commit();
	}
	catch {
		$self->log->error('Command load_rates error:' . $_);
		$self->app->db->rollback();
	};
	return 1;
}

1;
