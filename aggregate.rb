class Aggregate
  attr_reader :mean, :count, :max, :min, :sum, :outliers_low, :outliers_high
 
  # By default maintain a logarithmic histogram
  @@LOG_BUCKETS = 128

  #
  ## Constructor
  #
  def initialize (low=nil, high=nil, width=nil)
    @count = 0
    @sum = 0.0
    @sum2 = 0.0
    @outliers_low = 0
    @outliers_high = 0

    # If the user asks we maintain a linear histogram
    # STILL UNDER TEST/DEV
    if 0 #(nil != low && nil != high && nil != width)
      # This is a linear histogram
      if high < low
	raise ArgumentError, "High bucket must be > Low bucket"
      end

      @low = low
      @high = high
      @width = width
    else
      @low = 1
      @high = to_bucket(@@LOG_BUCKETS - 1)
    end

    #Initialize all buckets to 0
    @buckets = Array.new(bucket_count, 0)
  end

  #
  ## The aggregation operator
  #
  def << data

    # Update min/max
    if 0 == @count
      @min = data
      @max = data
    elsif data > @max
      @max = data
    elsif data < @min
      @min = data
    end

    # Update the running info
    @count += 1 
    @sum += data
    @sum2 += (data * data)

    # Update the bucket
    @buckets[to_index(data)] += 1 unless outlier?(data)
  end

  def mean
    @sum / self.count
  end

  def std_dev
  end

  def to_s

    #Find the largest bucket and create an array of the rows we intend to print
    max_count = 0
    disp_buckets = Array.new
    @buckets.each_with_index do |count, idx|
      next if 0 == count
      max_count = count if max_count < count
      disp_buckets << [idx, to_bucket(idx), count]
    end

    #Figure out how wide the value and count columns need to be based on their
    #largest respective numbers
    value_width = [disp_buckets.last[1].to_s.length, "value".length].max
    count_width = [max_count.to_s.length, "count".length].max
    max_bar_width  = 80 - (value_width + " |".length + " ".length + count_width)

    #print the header
    header = sprintf("%#{value_width}s", "value")
    header += " |"
    max_bar_width.times { header += "-"}
    header += " count"

    #Determine the value of a '@'
    weight = [max_count.to_f/max_bar_width.to_f, 1.0].max

    #Loop through each bucket to be displayed and output the correct number
    histogram = ""
    prev_index = disp_buckets[0][0] - 1
    disp_buckets.each do |x|

      #Denote skipped empty buckets with a ~
      histogram += "      ~\n" unless prev_index == x[0] - 1
      prev_index = x[0]

      #Add the value
      row = sprintf("%#{value_width}d |", x[1])

      #Add the bar
      bar_size = (x[2]/weight).to_i
      bar_size.times { row += "@"}
      (max_bar_width - bar_size).times { row += " " }

      #Add the count
      row += sprintf(" %#{count_width}d\n", x[2])

      #Append the finished row onto the histogram
      histogram += row
    end

    #Put the pieces together
    "\n" + header + "\n" + histogram 
  end
  
  #Histogram data can also be accessed through iterators
  def each
    @buckets.each_with_index do |count, index|
      yield(to_bucket(index), count)
    end
  end

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
    elsif data > @high
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
      return @low + ( (index + 1) * @width)
    else
      return 2**(index)
    end
  end
    
  def right_bucket?(index, data)
    bucket = to_bucket(index)

    # Edge case
    if 0 == index
      prev_bucket = @low
    else
      prev_bucket = to_bucket(index - 1)
    end

    #It's the right bucket if data falls between prev_bucket and bucket
    prev_bucket <= data && data <= bucket
  end

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

  # A data point is added to the bucket[n] where the data point
  # is less than the value represented by bucket[n], but greater
  # than the value represented by bucket[n+1]
  def to_index (data)

    if linear?
      find_bucket(0, bucket_count-1, data)
    else
      #log2 returns the bucket above the one we want,
      #and we need to also subtract for 0 indexing of Array
      log2(data).to_i
    end

  end

  # log2(x) returns j, | i = j-1 and 2**i <= data < 2**j
  def log2( x )
   Math.log(x) / Math.log(2)
  end
 
end
