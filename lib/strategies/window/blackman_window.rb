class BlackmanWindow < WindowStrategy
    def initialize(size: nil , norm_trans_freq: nil)
        super(size: norm_trans_freq.nil? ? size : find_size(norm_trans_freq))
        #size = @size + 2
        #@equation = lambda { |n| 0.42 - 0.5 * Math.cos(2 * PI * (n + 1) / (size - 1)) + 0.08 * Math.cos(4*PI*(n + 1) / (size - 1)) }
        @equation = lambda { |n| 0.42 - 0.5 * Math.cos(2 * PI * (n) / (size - 1)) + 0.08 * Math.cos(4*PI*(n) / (size - 1)) }
        calculate
        @values = @values.take(@size)
    end

    def find_size(freq)
        size = 5.5 / freq
        make_odd(size.ceil)
    end

    def transition_width
        5.5 / @size
    end
end