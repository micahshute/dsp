module FourierTransformable

    def self.included(base)
        base.class_eval do 
            include RequiresData
        end
    end

    attr_accessor :fft_strategy, :fft

    def initialize(time_data: , fft_strategy: Radix2Strategy)
        @fft_strategy = Radix2Strategy
        @fft = Dsp::FFT.new(time_data: time_data.dup)
    end

    def fft_db
        setup_fft
        @fft.fft.db
    end

    def fft_magnitude
        setup_fft
        @fft.magnitude
    end

    def fft_data
        setup_fft
        @fft.fft
    end

    def fft_angle
        setup_fft
        @fft.angle
    end

    def fft_real
        setup_fft
        @fft.real
    end

    def fft_imaginary
        setup_fft
        @fft.fft.imaginary
    end

    private

    def setup_fft
        self.fft.calculate if self.fft.fft.nil?
    end

end