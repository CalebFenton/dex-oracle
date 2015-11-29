class SmaliField
    attr_reader :name, :class, :type, :descriptor

    def initialize(class_name, field_signature)
        @class = class_name
        @descriptor = "#{class_name}->#{field_signature}"
        @name, @type = field_signature.split(':')
    end

    def to_s
        @descriptor
    end

    def ==(o)
        o.class == self.class && o.state == state
    end

    def state
        [@name, @type, @descriptor]
    end
end
