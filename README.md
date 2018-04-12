# ruby-gcs

This is a small Ruby library for querying Golomb Compressed Set files as produced
by [gcstool][1].

You might use it to query a leaked password database or something.  Note that
as of today this is just the bare minimum needed to make it work, it's not a
production-ready well-tested gem.

## Usage

    gcs = GCS::Reader.new(File.new('pwned-passwords-2.0.gcs'))
    hash = Digest::SHA1.hexdigest("password")[0..16].to_i(16)
    gcs.exists?(hash) # => true
    hash = Digest::SHA1.hexdigest("not a leaked password")[0..16].to_i(16)
    gcs.exists?(hash) # => false


[1]: https://github.com/Freaky/gcstool
