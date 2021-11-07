CREATE TABLE currencies
(
    id serial,
    symbol character varying(5) NOT NULL,
    ctime timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT currencies_pkey PRIMARY KEY (id)
);

CREATE TABLE update_rates
(
    id serial,
    ctime timestamp without time zone,
    CONSTRAINT update_rates_pkey PRIMARY KEY (id)
);

CREATE TABLE rates
(
    id serial,
    currency_id integer NOT NULL,
    update_rate_id integer NOT NULL,
    rates json,
    ctime timestamp without time zone,
    CONSTRAINT rates_pkey PRIMARY KEY (id),
    CONSTRAINT fk_currency_id FOREIGN KEY (currency_id)
        REFERENCES currencies (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_update_rate_id FOREIGN KEY (update_rate_id)
        REFERENCES update_rates (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);
