require 'minitest/autorun'
require 'aggregate'

class SimpleStatsTest < MiniTest::Test

  def setup
    @stats = Aggregate.new

    @@DATA.each do |x|
      @stats << x
    end
  end

  def test_stats_count
    assert_equal @@DATA.length, @stats.count
  end

  def test_stats_min_max
    sorted_data = @@DATA.sort

    assert_equal sorted_data[0], @stats.min
    assert_equal sorted_data.last, @stats.max
  end

  def test_stats_mean
    sum = 0
    @@DATA.each do |x|
      sum += x
    end

    assert_equal sum.to_f/@@DATA.length.to_f, @stats.mean
  end

  def test_bucket_counts

    #Test each iterator
    total_bucket_sum = 0
    i = 0
    @stats.each do |bucket, count|
      assert_equal 2**i, bucket
      
      total_bucket_sum += count
      i += 1
    end

    assert_equal total_bucket_sum, @@DATA.length

    #Test each_nonzero iterator
    prev_bucket = 0
    total_bucket_sum = 0
    @stats.each_nonzero do |bucket, count|
      assert bucket > prev_bucket
      refute_equal count, 0

      total_bucket_sum += count
    end

    assert_equal total_bucket_sum, @@DATA.length
  end

=begin
  def test_addition
    stats1 = Aggregate.new
    stats2 = Aggregate.new

    stats1 << 1
    stats2 << 3

    stats_sum = stats1 + stats2

    assert_equal stats_sum.count, stats1.count + stats2.count
  end
=end

  #XXX: Update test_bucket_contents() if you muck with @@DATA
  @@DATA = [ 1, 5, 4, 6, 1028, 1972, 16384, 16385, 16383]
  def test_bucket_contents
    #XXX: This is the only test so far that cares about the actual contents
    # of @@DATA, so if you update that array ... update this method too
    expected_buckets  = [1, 4, 1024, 8192, 16384]
    expected_counts =   [1, 3,    2,    1,     2]

    i = 0
    @stats.each_nonzero do |bucket, count|
      assert_equal expected_buckets[i], bucket
      assert_equal expected_counts[i],  count
      # Increment for the next test
      i += 1
    end
  end

  def test_histogram
    puts @stats.to_s
  end

  def test_outlier
    assert_equal 0, @stats.outliers_low
    assert_equal 0, @stats.outliers_high

    @stats << -1
    @stats << -2
    @stats << 0

    @stats << 2**128

    # This should be the last value in the last bucket, but Ruby's native
    # floats are not precise enough. Somewhere past 2^32 the log(x)/log(2)
    # breaks down. So it shows up as 128 (outlier) instead of 127
    #@stats << (2**128) - 1

    assert_equal 3, @stats.outliers_low
    assert_equal 1, @stats.outliers_high
  end

  def test_std_dev
    @stats.std_dev
  end
end

class LinearHistogramTest < MiniTest::Test
  def setup
    @stats = Aggregate.new(0, 32768, 1024)

    @@DATA.each do |x|
      @stats << x
    end
  end

  def test_validation

    # Range cannot be 0
    assert_raises(ArgumentError) {bad_stats = Aggregate.new(32,32,4)}

    # Range cannot be negative
    assert_raises(ArgumentError) {bad_stats = Aggregate.new(32,16,4)}

    # Range cannot be < single bucket
    assert_raises(ArgumentError) {bad_stats = Aggregate.new(16,32,17)}

    # Range % width must equal 0 (for now)
    assert_raises(ArgumentError) {bad_stats = Aggregate.new(1,16384,1024)}
  end

  #XXX: Update test_bucket_contents() if you muck with @@DATA
  # 32768 is an outlier
  @@DATA = [ 0, 1, 5, 4, 6, 1028, 1972, 16384, 16385, 16383, 32768]
  def test_bucket_contents
    #XXX: This is the only test so far that cares about the actual contents
    # of @@DATA, so if you update that array ... update this method too
    expected_buckets  = [0, 1024,  15360, 16384]
    expected_counts =   [5, 2,     1,     2]

    i = 0
    @stats.each_nonzero do |bucket, count|
      assert_equal expected_buckets[i], bucket
      assert_equal expected_counts[i],  count
      # Increment for the next test
      i += 1
    end
  end

end
