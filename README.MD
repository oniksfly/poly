# Poly API scenarios runner
Simple API scenarios runner.

## How to use
Run with arguments:

```bash
ruby scenario.rb
```

### Environment variables
* host - Server hostname, e. g. `crmsport.ru`.
* port - Server backend port, e. g. `80`.

So you can run with this variables:

```bash
host=crmsport.ru port=80 ruby scenario.rb
```

## Available commands

#### User sign in
`user_sign_in(email:, password:)`

#### Users list
`users_list`

#### Teams list
`teams_list`

#### Sleep for X seconds
`sleep_seconds(seconds)`