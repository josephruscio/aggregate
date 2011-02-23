# Implements aggregate statistics and maintains
# configurable histogram for a set of given samples. Convenient for tracking
# high throughput data.
class Aggregate
  #The current number of samples
  attr_reader :count

  #The maximum sample value
  attr_reader :max

  #The minimum samples value
  attr_reader :min

  #The sum of all samples
  attr_reader :sum

  #The number of samples falling below the lowest valued histogram bucket
  attr_reader :outliers_low

  #The number of samples falling above the highest valued histogram bucket
  attr_reader :outliers_high

  # The number of buckets in the binary logarithmic histogram (low => 2**0, high => 2**@@LOG_BUCKETS)
  @@LOG_BUCKETS = 128

  # Create a new Aggregate that maintains a binary logarithmic histogram
  # by default. Specifying values for low, high, and width configures
  # the aggregate to maintain a linear histogram with (high - low)/width buckets
  def initialize (low=nil, high=nil, width=nil)
    @count = 0
    @sum = 0.0
    @sum2 = 0.0
    @outliers_low = 0
    @outliers_high = 0

    # If the user asks we maintain a linear histogram where
    # values in the range [low, high) are bucketed in multiples
    # of width
    if (nil != low && nil != high && nil != width)

      #Validate linear specification
      if high <= low
	raise ArgumentError, "High bucket must be > Low bucket"
      end

      if high - low < width
        raise ArgumentError, "Histogram width must be <= histogram range"
      end

      if 0 != (high - low).modulo(width)
	raise ArgumentError, "Histogram range (high - low) must be a multiple of width"
      end

      @low = low
      @high = high
      @width = width
    else
      @low = 1
      @width = nil
      @high = to_bucket(@@LOG_BUCKETS - 1)
    end

    #Initialize all buckets to 0
    @buckets = Array.new(bucket_count, 0)
  end

  # Include a sample in the aggregate
  def << data

    # Update min/max
    if 0 == @count
      @min = data
      @max = data
    else
      @max = data if data > @max
      @min = data if data < @min
    end

    # Update the running info
    @count += 1
    @sum += data
    @sum2 += (data * data)

    # Update the bucket
    @buckets[to_index(data)] += 1 unless outlier?(data)
  end

  #The current average of all samples
  def mean
    @sum / @count
  end

  #Calculate the standard deviation
  def std_dev
    Math.sqrt((@sum2.to_f - ((@sum.to_f * @sum.to_f)/@count.to_f)) / (@count.to_f - 1))
  end

  # Combine two aggregates
  #def +(b)
  #  a = self
  #  c = Aggregate.new

  #  c.count = a.count + b.count
  #end

  #Generate a pretty-printed ASCII representation of the histogram
  def to_s(columns=nil)

    #default to an 80 column terminal, don't support < 80 for now
    if nil == columns
      columns = 80
    else
      raise ArgumentError if columns < 80
    end

    #Find the largest bucket and create an array of the rows we intend to print
    disp_buckets = Array.new
    max_count = 0
    total = 0
    @buckets.each_with_index do |count, idx|
      next if 0 == count
      max_count = [max_count, count].max
      disp_buckets << [idx, to_bucket(idx), count]
      total += count
    end

    #XXX: Better to print just header --> footer
    return "Empty histogram" if 0 == disp_buckets.length

    #Figure out how wide the value and count columns need to be based on their
    #largest respective numbers
    value_str = "value"
    count_str = "count"
    total_str = "Total"
    value_width = [disp_buckets.last[1].to_s.length, value_str.length].max
    value_width = [value_width, total_str.length].max
    count_width = [total.to_s.length, count_str.length].max
    max_bar_width  = columns - (value_width + " |".length + "| ".length + count_width)

    #Determine the value of a '@'
    weight = [max_count.to_f/max_bar_width.to_f, 1.0].max

    #format the header
    histogram = sprintf("%#{value_width}s |", value_str)
    max_bar_width.times { histogram << "-"}
    histogram << sprintf("| %#{count_width}s\n", count_str)

    # We denote empty buckets with a '~'
    def skip_row(value_width)
      sprintf("%#{value_width}s ~\n", " ")
    end

    #Loop through each bucket to be displayed and output the correct number
    prev_index = disp_buckets[0][0] - 1

    disp_buckets.each do |x|
      #Denote skipped empty buckets with a ~
      histogram << skip_row(value_width) unless prev_index == x[0] - 1
      prev_index = x[0]

      #Add the value
      row = sprintf("%#{value_width}d |", x[1])

      #Add the bar
      bar_size = (x[2]/weight).to_i
      bar_size.times { row += "@"}
      (max_bar_width - bar_size).times { row += " " }

      #Add the count
      row << sprintf("| %#{count_width}d\n", x[2])

      #Append the finished row onto the histogram
      histogram << row
    end

    #End the table
    histogram << skip_row(value_width) if disp_buckets.last[0] != bucket_count-1
    histogram << sprintf("%#{value_width}s", "Total")
    histogram << " |"
    max_bar_width.times {histogram << "-"}
    histogram << "| "
    histogram << sprintf("%#{count_width}d\n", total)
  end

  #Iterate through each bucket in the histogram regardless of
  #its contents
  def each
    @buckets.each_with_index do |count, index|
      yield(to_bucket(index), count)
    end
  end

  #Iterate through only the buckets in the histogram that contain
  #samples
  def each_nonzero
    @buckets.each_with_index do |count, index|
      yield(to_bucket(index), count) if count != 0
    end
  end

  private

  def linear?
    nil != @width
  end

  def outlier? (data)

    if data < @low
      @outliers_low += 1
    elsif data >= @high
      @outliers_high += 1
    else
      return false
    end
  end

  def bucket_count
    if linear?
      return (@high-@low)/@width
    else
      return @@LOG_BUCKETS
    end
  end

  def to_bucket(index)
    if linear?
      return @low + (index * @width)
    else
      return 2**(index)
    end
  end

  def right_bucket? index, data

    # check invariant
    raise unless linear?

    bucket = to_bucket(index)

    #It's the right bucket if data falls between bucket and next bucket
    bucket <= data && data < bucket + @width
  end

=begin
  def find_bucket(lower, upper, target)
    #Classic binary search
    return upper if right_bucket?(upper, target)

    # Cut the search range in half
    middle = (upper/2).to_i

    # Determine which half contains our value and recurse
    if (to_bucket(middle) >= target)
      return find_bucket(lower, middle, target)
    else
      return find_bucket(middle, upper, target)
    end
  end
=end

  # A data point is added to the bucket[n] where the data point
  # is less than the value represented by bucket[n], but greater
  # than the value represented by bucket[n+1]
  def to_index (data)

    # basic case is simple
    return log2(data).to_i if !linear?

    # Search for the right bucket in the linear case
    @buckets.each_with_index do |count, idx|
      return idx if right_bucket?(idx, data)
    end
    #find_bucket(0, bucket_count-1, data)

    #Should not get here
    raise "#{data}"
  end

  # log2(x) returns j, | i = j-1 and 2**i <= data < 2**j
  @@LOG2_DIVEDEND = Math.log(2)
  def log2( x )
   Math.log(x) / @@LOG2_DIVEDEND
  end

end
