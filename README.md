# ruby-gcs

This is a small prerelease Ruby library for generating and querying
[Golomb Compressed Set][1] databases, as produced by [gcstool][2].

Golomb Compressed Sets are similar to [Bloom filters][3] - they're space-efficient
data structures that let you test whether a given element is a member of a set.

Like Bloom filters, they have a controllable rate of false-positives - they may
consider an element a member of a set even if it's never been seen before - while
having no false negatives.  If a GCS hasn't seen it, it's not on the list.

Their main benefit over Bloom filters is being a little more compact - particularlly
with larger lists and better false-positive rates.

## Usage

ruby-gcs comes with two small command-line utilities to create and query GCS databases.

### bin/create

    % wc -l /usr/share/dict/words
      235924 words
    % gzip --stdout -9 /usr/share/dict/words >words.gz && du -Ah words.gz
      737K    words.gz
    % bin/create 10000000 /usr/share/dict/words words-p10m.gcs
    % du -Ah words-p10m.gcs
      741K    words-p10m.gcs

So, about the same size as a gzip -9 file, at the expense of 1 in every 10 million
queries for words not in the dictionary being "found".

### bin/query

    % bin/query words-p10m.gcs
    abiogenesis
    Found in 0.77ms
    llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch
    Not found in 1.73ms

Refer to these to see how the API works.

The full 500 million-strong pwned-passwords-2.0.txt imports to 1.5GB with a 1 in
10 million false-positive rate - some improvement on the 9GB compressed hash list,
30GB uncompressed text file, or 1.95GB Bloom filter.

You're advised to use gcstool for generating such large databases, as it's both much
faster (~20x) and much more memory efficient (~8x).

## TODO

 * Test suite.
 * Less basic tools.
 * On-disk intermediate state for building large files.
 * Better documentation.
 * Plugin for [Rodauth][5].


[1]: http://giovanni.bajo.it/post/47119962313/golomb-coded-sets-smaller-than-bloom-filters
[2]: https://github.com/Freaky/gcstool
[3]: https://en.wikipedia.org/wiki/Bloom_filter
[4]: https://haveibeenpwned.com/Passwords
[5]: http://rodauth.jeremyevans.net/
