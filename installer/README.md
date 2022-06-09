## mix grf.new

Provides `grf.new` installer as an archive.

To install from Hex, run:

    $ mix archive.install hex grf_new

To build and install it locally,
ensure any previous archive versions are removed:

    $ mix archive.uninstall grf_new

Then run:

    $ cd installer
    $ MIX_ENV=prod mix do archive.build, archive.install