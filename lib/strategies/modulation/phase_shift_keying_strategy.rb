class Digiproc::Strategies::PSK

    attr_accessor :m, :modulating_signal , :carrier_signal_eqn, :coding_strategy, :phase_shift_eqn, :signal_to_phase, :coded_signal, :phase_signal, :carrier_frequency, :pulse_length

    ##
    # == Initialize Args
    # modulating_signal:: Array[String]; each element is a "symbol" (should be a string reprisenting bits), where a symnbol is a number of bits symbolizing a single character (ie symbol means character)
    # carrier_signal_eqn (optional):: Lambda (or Proc) default value is: ->(a, fo, t, theta){ a * Math.cos(2*Math::PI * fo * t + theta) }
    # coding_strategy (optional):: Protocol, see Digiproc::Strategies::XORDifferentialEncodingZeroAngleStrategy, default value is nil
    # carrier_frequency (optional)::Numeric (in Hz), defaults to 10000
    # pulse_length (optional):: Float (in seconds), defaults to 0.00015 determines how long to apply a phase shift
    def initialize(carrier_signal_eqn: ->(a, fo, t, theta){ a * Math.cos(2*Math::PI * fo * t + theta) }, modulating_signal: ,coding_strategy: nil, carrier_frequency: 10000, pulse_length: 0.00015)
        @carrier_signal_eqn, @modulating_signal, @coding_strategy, @carrier_frequency, @pulse_length = carrier_signal_eqn, modulating_signal, coding_strategy, carrier_frequency, pulse_length
        @m = 2 ** modulating_signal.first.length 
        if coding_strategy.nil?
            @phase_shift_eqn = ->(i){ (2.0 * Math::PI * (i)) / @m }
            @coded_signal = @modulating_signal
        else
            @phase_shift_eqn = coding_strategy.phase_shift_eqn(@m)
            @coded_signal = coding_strategy.encode modulating_signal, @m, "0"
        end
        @signal_to_phase = {}
        for i in 0...@m do
            @signal_to_phase[i.to_s] = @phase_shift_eqn[i]
        end

        @phase_signal = @coded_signal.map{ |coded_symbol| @phase_shift_eqn[coded_symbol.to_i(2)] }

    end

    ##
    # == Input Args
    # a (optional):: Numeric for amplitude of the signal (default value = 1)
    # Return Digiproc::AnalogSignal of the Phase Shift Keyed signal
    def output(a: 1)
        eqn = Proc.new do |t|
            theta_index = (t.to_f / @pulse_length.to_f).floor
            @carrier_signal_eqn[a, @carrier_frequency, t, @phase_signal[theta_index]]
        end
        sample_rate = 0.01 / @carrier_frequency
        size = @pulse_length.to_f * @phase_signal.length / sample_rate
        Digiproc::AnalogSignal.new(eqn: eqn, sample_rate: sample_rate, size: size)
    end 

    ##
    # Apply inverse of the PSK strategy to decode the PSK signal
    def decode
        eqn = coding_strategy.nil? ? decode_eqn : coding_strategy.phase_to_sym(@m)
        sym = @phase_signal.map{ |phase| eqn[phase] }
        sym = coding_strategy.decode(sym) if not coding_strategy.nil?
        return sym
    end

    ##
    # Based off of reciever Figure 4-15 INTRODUCTION TO DIGITAL COMMUNICATIONS, ZIEMER, PETERSON pg 237
    # NOTE: SUBOPTIMUM DETECTOR, optimum detector referenced on the above page, different reference
    # This simulates a real-life reciever recieving the siglans and decoding them
    def reciever_decode
        recieved = output.to_ds.fft.magnitude
        ts = 1 / (@carrier_frequency / 0.01)
        max_freq = 1.0 / ts
        normalized_target = @carrier_frequency / max_freq.to_f
        bw = (0.57 / ts) / max_freq.to_f
        plt = Digiproc::QuickPlot
        factory = Digiproc::Factories::FilterFactory
        bpf = factory.filter_for(type: "bandpass", wo: normalized_target * Math::PI * 2, bw: bw * Math::PI * 2, transition_width: 0.0001, stopband_attenuation: 80)
        bpf.fft.calculate_at_size(2 ** 16)

        filtered = (bpf.fft * output.to_ds.fft(2** 16)).ifft.map(&:real)
        sample_interval = @pulse_length / (0.01 / @carrier_frequency)
        output = []
        for i in (sample_interval + 1).to_i...filtered.length do 
            output << (filtered[i] * filtered[i-sample_interval]) 
        end
        lpf = factory.filter_for(type: "lowpass", wc: 2 * Math::PI / 4, transition_width: 0.0001, stopband_attenuation: 80)
        outft = Digiproc::FFT.new(time_data: output, size: 2 ** 16)
        
        # TODO FIND WHERE SIGNAL BEGINS AND OUTPUT THE SIGNAL BASED OFF OF 
        # SIGNAL SIZE. ALSO, THERE SHOULD BE A RECIEVER METHOD OR SEPERATE CLASS
        # WHICH OUPUTS THE RAW DATA OF THE RECIEVERS
        data = (outft * lpf.fft).ifft.map(&:real)
        all_out = @phase_signal.size > 200 ? data[55000,  200 * sample_interval].concat(data[0, sample_interval * (@phase_signal.size - 200)]) : data[55000,  @phase_signal.size * sample_interval]
        final_out = []
        for i in 0...all_out.length do
            final_out << all_out[i] if (i + 10) %  sample_interval == 0 
        end
        final_out
    end


    private

    def decode_eqn
        ->(phase){ (phase * @m / (2.0 * Math::PI))}
    end
end 