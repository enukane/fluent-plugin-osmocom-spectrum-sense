# Fluent::Plugin::OsmocomSpectrumSense

fluent-plugin-osmocom-spectrum-sense is an input plugin for Fluentd. It runs osmocom_spectrum_sense with specified arguments and extract frequencies, powers, noise floor (dBm) from its output.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-osmocom-spectrum-sense'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-osmocom-spectrum-sense

## Usage

See samples/text.conf

```
<source>
  @type osmocom_spectrum_sense

 tag osmocom
  minfreq 79000000
  maxfreq 83000000
  sample_rate 3200000
  dwell_delay 1
  tune_delay 1
</source>
```

## Configuration

|name|type|required?|corresponds to...|default|description|
|:---|:---|:--------|:----------------|:------|:----------|
|minfreq|int|required|min_freq|none|Minimum Frequency|
|maxfreq|int|required|max_freq|none|Maximum Frequency|
|sample_rate|int|optional|-s, --sample-rate|3200000 (3.2Msps)|Sample rate|
|dwell_delay|float|optional|--dwell-delay|0.25 (0.25s)|Seconds to dwell at a given frequency|
|tune_delay|float|optional|--tune-delay|0.25 (0.25s)|Seconds to delay after changing frequency|
|channel_bandwidth|float|optional|-b, --channel-bandwidth|6250.0 (6.25KHz)|Channel bandwidth of fft bins in Hz|

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

