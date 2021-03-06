
## 
# A module for classes which have other modules which can accept parameters from the class.
# For example when included in a class, `Digiproc::FourierTransformable` automatically also includes
# 'Digiproc::Initializable' because `Digiproc::FourierTransformable` needs time data (and an optional Strategy) to
# generate the FFT for the data in the class. While another appropriate pattern could be to make the `Digiproc::FFT` generation
# lazy, and just pull the `time_data` from the class' `data` property when any fft property is first queried, this pattern
# allows more flexibility by allowing more customizable setup during instantiation
module Digiproc::Initializable

    ##
    # Adds a `initialize_modules` method to the including class which allows you to call `initialize_modules(*modules)`
    # where *modules can be Modules or a hash of Module => {params: params_values} for module initialization. 
    # Modules which support initialization have an `initialize` method that can be called in this way
    # See `Digiproc::DigitalSignal` for an example
    ## initialize_modules(Module => { module_initializer_accepts_key: value, another_key: value2})
    def self.included(base)
        base.class_eval do 
            def initialize_modules(*modules)
                modules.each do |m|
                    if verify_params(m) == :valid_hash
                       m.keys.first.instance_method(:initialize).bind(self).call(m.values.first)
                    elsif verify_params(m) == :valid_module
                        m.instance_method(:initialize).bind(self).call
                    end
                end
            end

            private

            def verify_params(item)
                return :valid_module if item.is_a? Module
                if item.is_a? Hash
                    return :valid_hash if item.keys.length == 1 and item.keys.first.is_a? Module
                end
                raise ArgumentError.new("Each argument must either be a module or a hash of type Module => args")
            end

        end
    end

   
end