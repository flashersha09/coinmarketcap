package App::Model::UpdateRates;
use Mojo::Base 'App::Model';

has columns => sub { [qw/
	id ctime
/] };

1;
