
class Dsp::FFT

    
    def self.calculate(time_data)
        Radix2Strategy.calculate(time_data)
    end

    def self.new_from_spectrum(data)
        time_data = Dsp::Strategies::IFFTConjugateStrategy.new(data)
        new(freq_data: data, time_data: time_data)
    end

    def data
        calculate if @data.nil?
        @data
    end

    attr_accessor :strategy, :window, :processed_time_data, :time_data_size, :inverse_strategy
    include Dsp::Convolvable::InstanceMethods, Dsp::Plottable::InstanceMethods

    #Using size wiht a Radix2Strategy will only ensure a minimum amount of 
    #zero-padding, it will mostly likely not determine the final size of the time_data
    def initialize(strategy: Dsp::Strategies::Radix2Strategy, time_data: nil, size: nil, window: Dsp::RectangularWindow, freq_data: nil, inverse_strategy: Dsp::Strategies::IFFTConjugateStrategy)
        raise ArgumentError.new("Either time or frequency data must be given") if time_data.nil? and freq_data.nil?
        raise ArgumentError.new('Size must be an integer') if not size.nil? and not size.is_a?(Integer) 
        raise ArguemntError.new('Size must be greater than zero') if not size.nil? and size <= 0 
        raise ArgumentError.new('time_data must be an array') if not time_data.respond_to?(:calculate) and not time_data.is_a? Array
        
        if time_data.is_a? Array
            @time_data_size = time_data.length
            if not size.nil?
                if size <= time_data.length
                    @time_data = time_data.dup.map{ |val| val.dup }.take(size)
                else 
                    zero_fill = Array.new(size - time_data.length, 0)
                    @time_data = time_data.dup.map{ |val| val.dup }.concat zero_fill
                end
            else
                @time_data = time_data.dup.map{ |val| val.dup}
            end
            @strategy = strategy.new(@time_data.map{ |val| val.dup})
            @window = window.new(size: time_data_size)
        else
            @time_data = time_data
            @strategy = strategy.new
            @window = window.new(size: freq_data.length)
        end
        @inverse_strategy = inverse_strategy
        @data = freq_data
    end

    def calculate
        self.strategy.data = time_data if @strategy.data.nil?
        @fft = self.strategy.calculate
        @data = @fft
    end

    def calculate_at_size(size)
        if size > self.data.size
            zero_fill = Array.new(size - @time_data.length, 0)
            @time_data = time_data.concat zero_fill
        elsif size < self.data.size
            @time_data = time_data.take(size)
        end
        self.strategy.data = time_data
        calculate
    end

    def ifft
        inverse_strategy.new(data).calculate
    end

    def ifft_ds
        Dsp::DigitalSignal.new(data: ifft)
    end


    def time_data
        if @time_data.is_a? Array
            @time_data
        elsif @time_data.respond_to? :calculate
            @time_data = @time_data.calculate
        else
            raise TypeError.new("time_data needs to be an array or an ifft strategy, not a #{@time_data.class}")
        end
    end

    def process_with_window
        @processed_time_data = time_data.take(time_data_size).times self.window.values
        self.strategy.data = @processed_time_data
        @fft = self.strategy.calculate
        @data = @fft
    end

    def fft
        self.data
    end

    def size
        self.data.length
    end

    def magnitude
        data.map do |f|
            f.abs
        end
    end

    def conjugate
        self.data.map(&:conjugate)
    end

    def dB
        self.magnitude.map do |m|
            Math.db(m)
        end
    end

    def angle
        self.data.map(&:angle)
    end

    def real
        self.data.map(&:real)
    end

    def imaginary
        self.data.map(&:imaginary)
    end

    def maxima(num = 1)
        Dsp::DataProperties.maxima(self.magnitude, num)
    end

    def local_maxima(num = 1)
        Dsp::DataProperties.local_maxima(self.magnitude, num)
    end

    def *(obj)
        if obj.respond_to?(:data) 
            return self.class.new_from_spectrum(self.data.times obj.data)
        elsif obj.is_a? Array 
            return self.class.new_from_spectrum(self.data.times obj)
        end
    end

    def plot_db(path: "./") 
        self.plot(method: :dB, xsteps: 8, path: path) do |g|
            g.title = "Decibles"
            g.x_axis_label = "Normalized Frequency"
            g.y_axis_label = "Magnitude"
        end
    end

    def plot_magnitude(path: "./" )
        self.plot(method: :magnitude, xsteps: 8, path: path) do |g|
            g.title = "Magnitude"
            g.x_axis_label = "Normalized Frequency"
            g.y_axis_label = "Magnitude"
        end
    end


    def graph_magnitude(file_name = "fft")
        if @fft
            g = Gruff::Line.new
            g.data :fft, self.magnitude
            g.write("./#{file_name}.png")
        end
    end

    def graph_time_data
        g = Gruff::Line.new
        g.data :data, @time_data
    end


end