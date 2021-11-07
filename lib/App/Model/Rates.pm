package App::Model::Rates;
use Mojo::Base 'App::Model';

has columns => sub { [qw/
	id currency_id update_rate_id rates ctime
/] };

has types => sub {
	{ rates => 'json' }
};

1;
